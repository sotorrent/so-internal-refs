package org.sotorrent.stint;

import org.apache.commons.csv.*;
import org.hibernate.*;
import org.hibernate.cfg.Configuration;
import org.sotorrent.util.LogUtils;
import org.sotorrent.util.collections.CollectionUtils;
import org.sotorrent.util.exceptions.ErrorUtils;

import javax.persistence.TypedQuery;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.LinkedList;
import java.util.List;
import java.util.Locale;
import java.util.logging.Logger;
import java.util.stream.Collectors;

public class EventIterator {

    static SessionFactory sessionFactory = null;
    private static Logger logger = null;

    private static final CSVFormat CSV_FORMAT_USER_IDENTIFIERS;
    private static final int LOG_PACE = 1000;
    private static final String USER_IDENTIFIERS_BASE_FILENAME = "user_identifiers";
    private static final int NAVIGATION_SEQUENCE_THRESHOLD_SECONDS = 360;
    private static final int BOT_TRAFFIC_THRESHOLD_SECONDS = 1;

    private final File dataDir;
    private final int partitionCount;

    static {
        // configure logger
        try {
            logger = LogUtils.getClassLogger(EventIterator.class);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // configure CSV format for in- and output
        CSV_FORMAT_USER_IDENTIFIERS = CSVFormat.DEFAULT
                .withHeader("UserIdentifier")
                .withDelimiter(',')
                .withQuote('"')
                .withQuoteMode(QuoteMode.MINIMAL)
                .withEscape('\\')
                .withNullString("");
    }

    public EventIterator(Path dataDirPath, int partitionCount) {
        this.partitionCount = partitionCount;
        this.dataDir = dataDirPath.toFile();

        // ensure that data dir exists
        try {
            if (!Files.exists(dataDirPath)) {
                Files.createDirectory(dataDirPath);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    static void createSessionFactory(Path hibernateConfigFilePath) {
        if (!Files.exists(hibernateConfigFilePath) || Files.isDirectory(hibernateConfigFilePath)) {
            throw new IllegalArgumentException("Not a valid hibernate config file: " + hibernateConfigFilePath);
        }

        sessionFactory = new Configuration()
                .addAnnotatedClass(Event.class)
                .configure(hibernateConfigFilePath.toFile())
                .buildSessionFactory();
    }

    void extractSaveAndSplitUserIdentifiers() {
        if (sessionFactory == null) {
            throw new IllegalStateException("Static session factory not created yet.");
        }

        Transaction t = null; // see https://docs.jboss.org/hibernate/orm/3.3/reference/en/html/transactions.html
        try (StatelessSession session = sessionFactory.openStatelessSession()) {
            logger.info("Retrieving user identifiers with more than one event from table Event...");
            String userIdentifiersQueryString = "SELECT userIdentifier FROM Event " +
                    "GROUP BY userIdentifier HAVING COUNT(*) > 1";

            t = session.beginTransaction();
            TypedQuery<String> userIdentifiersQuery = session.createQuery(userIdentifiersQueryString, String.class);
            List<String> userIdentifiers = userIdentifiersQuery.getResultList();
            logger.info(userIdentifiers.size() + " user identifiers retrieved.");
            t.commit();

            writeUserIdentifiersToCSV(userIdentifiers, USER_IDENTIFIERS_BASE_FILENAME + ".csv");
        } catch (RuntimeException e) {
            if (t != null) {
                t.rollback();
                e.printStackTrace();
            }
        }

        // split up retrieved user identifiers into partitions
        splitUserIdentifiers();
    }

    private void writeUserIdentifiersToCSV(List<String> userIdentifiers, String filename) {
        File outputFile = Paths.get(dataDir.toString(), filename).toFile();
        if (outputFile.exists()) {
            if (!outputFile.delete()) {
                throw new IllegalStateException("Error while deleting output file: " + outputFile);
            }
        }
        logger.info("Writing data to CSV file " + outputFile.getName() + " ...");
        try (CSVPrinter csvPrinter = new CSVPrinter(new FileWriter(outputFile), CSV_FORMAT_USER_IDENTIFIERS)) {
            // header is automatically written
            for (String userIdentifier : userIdentifiers) {
                csvPrinter.printRecord(userIdentifier);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private List<String> readUserIdentifiersFromCSV() {
        List<String> userIdentifiers = null;

        File inputFile = Paths.get(dataDir.toString(), USER_IDENTIFIERS_BASE_FILENAME + ".csv").toFile();
        if (!inputFile.exists()) {
            throw new IllegalArgumentException("Error while reading input file: " + inputFile);
        }
        logger.info("Reading file " + inputFile.getName() + " ...");

        try (CSVParser csvParser = new CSVParser(new FileReader(inputFile), CSV_FORMAT_USER_IDENTIFIERS.withFirstRecordAsHeader())) {
            // read all records into memory
            List<CSVRecord> records = csvParser.getRecords();
            userIdentifiers = records.stream()
                    .map(r -> r.get("UserIdentifier"))
                    .collect(Collectors.toList());
        } catch (IOException e) {
            e.printStackTrace();
        }

        return userIdentifiers;
    }

    private void splitUserIdentifiers() {
        List<String> userIdentifiers;
        List<String>[] subLists;

        logger.info("Splitting user identifiers...");
        userIdentifiers = readUserIdentifiersFromCSV();
        subLists = CollectionUtils.split(userIdentifiers, partitionCount);
        for (int i=0; i<subLists.length; i++) {
            List<String> list = subLists[i];
            writeUserIdentifiersToCSV(list, USER_IDENTIFIERS_BASE_FILENAME + "_" + i + ".csv");
        }
        logger.info("Splitting of user identifiers complete.");
    }

    void processEvents() {
        List<ExtractionThread> extractionThreads = new LinkedList<>();

        logger.info("Starting parallel processing of events...");

        for (int i=0; i<partitionCount; i++) {
            ExtractionThread thread = new ExtractionThread(i);
            extractionThreads.add(thread);
            thread.start();
            logger.info("Thread " + i + " started...");
        }

        try {
            for (int i=0; i<extractionThreads.size(); i++) {
                extractionThreads.get(i).join();
                logger.info("Thread " + i + " terminated.");
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        logger.info("Parallel processing of events finished.");
    }

    private class ExtractionThread extends Thread {
        private final String filename;
        private final int partition;

        ExtractionThread(int partition) {
            this.filename = USER_IDENTIFIERS_BASE_FILENAME + "_" + partition + ".csv";
            this.partition = partition;
        }

        @Override
        public void run() {
            extractDataFromEventLog(filename);
            logger.info("File " + filename + " has been processed.");
        }

        private void extractDataFromEventLog(String filename) {
            if (sessionFactory == null) {
                throw new IllegalStateException("Static session factory not created yet.");
            }

            // read user identifiers from CSV file and process them
            File inputFile = Paths.get(dataDir.toString(), filename).toFile();
            if (!inputFile.exists()) {
                throw new IllegalArgumentException("Thread " + partition + ": Error while reading input file: "
                        + inputFile);
            }
            logger.info("Thread " + partition + ": Reading file " + inputFile.getName() + " ...");
            logger.info("Thread " + partition + ": Identifying navigation sequences and setting root events...");

            // read all user identifiers from the CSV file and extract navigation sequences from table Event
            Transaction t = null; // see https://docs.jboss.org/hibernate/orm/3.3/reference/en/html/transactions.html
            try (StatelessSession session = sessionFactory.openStatelessSession()) {
                try (CSVParser csvParser = new CSVParser(
                        new FileReader(inputFile), CSV_FORMAT_USER_IDENTIFIERS.withFirstRecordAsHeader())) {

                    // read all records into memory
                    List<CSVRecord> records = csvParser.getRecords();
                    int recordCount = records.size();

                    logger.info("Thread " + partition + ": " + recordCount + " user identifiers read.");

                    int eventCount = 0;

                    // iterate over records
                    for (int recordIndex = 0; recordIndex < recordCount; recordIndex++) {
                        CSVRecord record = records.get(recordIndex);
                        String userIdentifier = record.get("UserIdentifier");

                        // log only every LOG_PACE record
                        if (recordIndex == 0 || recordIndex == recordCount - 1 || recordIndex % LOG_PACE == 0) {
                            // Locale.ROOT -> force '.' as decimal separator
                            String progress = String.format(Locale.ROOT, "%.2f%%", (((double) (recordIndex + 1)) / recordCount * 100));
                            logger.info("Thread " + partition + ": Current user identifier: " + userIdentifier
                                    + " (record " + (recordIndex + 1) + " of " + recordCount + "; " + progress + ")");
                        }

                        // get all events for current user identifier
                        String currentUserIdentifierQuery = String.format("FROM Event " +
                                        "WHERE UserIdentifier='%s' ORDER BY CreationDate ASC", userIdentifier
                        );

                        t = session.beginTransaction();

                        ScrollableResults eventIterator = session.createQuery(currentUserIdentifierQuery)
                                .scroll(ScrollMode.FORWARD_ONLY);


                        LinkedList<Event> currentSequence = new LinkedList<>();

                        while (eventIterator.next()) {
                            Event currentEvent = (Event) eventIterator.get(0);
                            currentSequence.add(currentEvent);

                            // set root event id
                            currentEvent.setRootEventId(currentSequence.getFirst().getId());

                            if (currentSequence.size() == 1 && eventIterator.isLast()) {
                                // not a sequence
                                currentEvent.setRootEventId(null);
                            } else if (currentSequence.size() > 1) {
                                Event previousEvent = currentSequence.get(currentSequence.size()-2);

                                // determine time difference to predecessor
                                currentEvent.setDiffSeconds(previousEvent);

                                // gap in event stream -> start new event sequence
                                if (currentEvent.getDiffSeconds() > NAVIGATION_SEQUENCE_THRESHOLD_SECONDS) {
                                    // check whether previous sequence had more than one event
                                    if (currentSequence.size() == 2) {
                                        // not a sequence
                                        previousEvent.setRootEventId(null);
                                        session.update(previousEvent);
                                    }
                                    // check whether new sequence has more than one event
                                    if (eventIterator.isLast()) {
                                        // not a sequence
                                        currentEvent.setRootEventId(null);
                                    } else {
                                        // set correct root event id for new sequence
                                        currentEvent.setRootEventId(currentEvent.getId());
                                    }
                                    // start new sequence
                                    currentSequence.clear();
                                    currentSequence.add(currentEvent);
                                } else {
                                    // determine whether sequence could be bot traffic
                                    // (access to same URL in short time frame)
                                    currentEvent.setBotTraffic(
                                            currentEvent.getDiffSeconds() < BOT_TRAFFIC_THRESHOLD_SECONDS
                                                    && currentEvent.getUrl().trim().equals(previousEvent.getUrl().trim())
                                    );
                                    // determine whether there is a gap in the sequence
                                    // (traffic not covered by the dataset or non-linear sequence)
                                    // check prefix, because referrers are often truncated
                                    currentEvent.setGapInSequence(
                                            !previousEvent.getEventTarget().equals(currentEvent.getEventSource())
                                                    || !previousEvent.getUrl().startsWith(currentEvent.getReferrer())
                                    );
                                }
                            }

                            // update event in database
                            session.update(currentEvent);

                            eventCount++;
                        }

                        // commit transaction
                        t.commit();
                    }

                    logger.info("Thread " + partition + ": " + eventCount + " events have been processed.");
                }
            } catch (Exception e) {
                logger.warning(ErrorUtils.exceptionStackTraceToString(e));
                if (t != null) {
                    t.rollback();
                }
            }
        }
    }
}
