package org.sotorrent.stint;

import org.apache.commons.csv.*;
import org.hibernate.*;
import org.hibernate.cfg.Configuration;
import org.sotorrent.util.LogUtils;
import org.sotorrent.util.URL;
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
import java.util.*;
import java.util.logging.Logger;
import java.util.stream.Collectors;

public class LinearSequenceIterator {

    static SessionFactory sessionFactory = null;
    private static Logger logger = null;

    private static final CSVFormat CSV_FORMAT_ROOT_EVENT_IDS;
    private static final int LOG_PACE = 1000;
    private static final String ROOT_EVENT_IDS_BASE_FILENAME = "root_event_ids";

    private File dataDir;
    private int partitionCount;

    static {
        // configure logger
        try {
            logger = LogUtils.getClassLogger(LinearSequenceIterator.class);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // configure CSV format for in- and output
        CSV_FORMAT_ROOT_EVENT_IDS = CSVFormat.DEFAULT
                .withHeader("RootEventId")
                .withDelimiter(',')
                .withQuote('"')
                .withQuoteMode(QuoteMode.MINIMAL)
                .withEscape('\\')
                .withNullString("");
    }

    public LinearSequenceIterator(Path dataDirPath, int partitionCount) {
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
                .addAnnotatedClass(LinearNonBotSequences.class)
                .configure(hibernateConfigFilePath.toFile())
                .buildSessionFactory();
    }

    void extractSaveAndSplitLinearNavigationSequences() {
        if (sessionFactory == null) {
            throw new IllegalStateException("Static session factory not created yet.");
        }

        Transaction t = null; // see https://docs.jboss.org/hibernate/orm/3.3/reference/en/html/transactions.html
        try (StatelessSession session = sessionFactory.openStatelessSession()) {
            logger.info("Retrieving linear navigation sequences from table LinearNonBotSequences...");
            String rootEventIdQueryString = "SELECT rootEventId FROM LinearNonBotSequences";

            t = session.beginTransaction();
            TypedQuery<Integer> rootEventIdQuery = session.createQuery(rootEventIdQueryString, Integer.class);
            List<Integer> rootEventIds = rootEventIdQuery.getResultList();
            logger.info(rootEventIds.size() + " linear navigation sequences retrieved.");
            t.commit();

            writeRootEventIdsToCSV(rootEventIds, ROOT_EVENT_IDS_BASE_FILENAME + ".csv");
        } catch (RuntimeException e) {
            if (t != null) {
                t.rollback();
                e.printStackTrace();
            }
        }

        // split up retrieved root event ids into partitions
        splitRootEventIds();
    }

    private void writeRootEventIdsToCSV(List<Integer> rootEventIds, String filename) {
        File outputFile = Paths.get(dataDir.toString(), filename).toFile();
        if (outputFile.exists()) {
            if (!outputFile.delete()) {
                throw new IllegalStateException("Error while deleting output file: " + outputFile);
            }
        }
        logger.info("Writing data to CSV file " + outputFile.getName() + " ...");
        try (CSVPrinter csvPrinter = new CSVPrinter(new FileWriter(outputFile), CSV_FORMAT_ROOT_EVENT_IDS)) {
            // header is automatically written
            for (Integer rootEventId : rootEventIds) {
                csvPrinter.printRecord(rootEventId);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private List<Integer> readRootEventIdsFromCSV() {
        List<Integer> rootEventIds = null;

        File inputFile = Paths.get(dataDir.toString(), ROOT_EVENT_IDS_BASE_FILENAME + ".csv").toFile();
        if (!inputFile.exists()) {
            throw new IllegalArgumentException("Error while reading input file: " + inputFile);
        }
        logger.info("Reading file " + inputFile.getName() + " ...");

        try (CSVParser csvParser = new CSVParser(new FileReader(inputFile), CSV_FORMAT_ROOT_EVENT_IDS.withFirstRecordAsHeader())) {
            // read all records into memory
            List<CSVRecord> records = csvParser.getRecords();
            rootEventIds = records.stream()
                    .map(r -> Integer.parseInt(r.get("RootEventId")))
                    .collect(Collectors.toList());
        } catch (IOException e) {
            e.printStackTrace();
        }

        return rootEventIds;
    }

    private void splitRootEventIds() {
        List<Integer> rootEventIds;
        List<Integer>[] subLists;

        logger.info("Splitting root event ids...");
        rootEventIds = readRootEventIdsFromCSV();
        subLists = CollectionUtils.split(rootEventIds, partitionCount);
        for (int i=0; i<subLists.length; i++) {
            List<Integer> list = subLists[i];
            writeRootEventIdsToCSV(list, ROOT_EVENT_IDS_BASE_FILENAME + "_" + i + ".csv");
        }
        logger.info("Splitting of root event ids complete.");
    }

    void processLinearNavigationSequences() {
        List<WorkerThread> workerThreads = new LinkedList<>();

        logger.info("Starting parallel processing of linear navigation sequences...");

        for (int i=0; i<partitionCount; i++) {
            WorkerThread thread = new WorkerThread(i);
            workerThreads.add(thread);
            thread.start();
            logger.info("Thread " + i + " started...");
        }

        try {
            for (int i=0; i<workerThreads.size(); i++) {
                workerThreads.get(i).join();
                logger.info("Thread " + i + " terminated.");
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        logger.info("Parallel processing of linear navigation sequences finished.");
    }

    private class WorkerThread extends Thread {
        private final String filename;
        private final int partition;

        WorkerThread(int partition) {
            this.filename = ROOT_EVENT_IDS_BASE_FILENAME + "_" + partition + ".csv";
            this.partition = partition;
        }

        @Override
        public void run() {
            processLinearNavigationSequences(filename);
            logger.info("File " + filename + " has been processed.");
        }

        private void processLinearNavigationSequences(String filename) {
            if (sessionFactory == null) {
                throw new IllegalStateException("Static session factory not created yet.");
            }

            // read root event ids from CSV file and process them
            File inputFile = Paths.get(dataDir.toString(), filename).toFile();
            if (!inputFile.exists()) {
                throw new IllegalArgumentException("Thread " + partition + ": Error while reading input file: "
                        + inputFile);
            }
            logger.info("Thread " + partition + ": Reading file " + inputFile.getName() + " ...");
            logger.info("Thread " + partition + ": Processing linear navigation sequences...");

            Transaction t = null; // see https://docs.jboss.org/hibernate/orm/3.3/reference/en/html/transactions.html
            try (StatelessSession session = sessionFactory.openStatelessSession()) {
                try (CSVParser csvParser = new CSVParser(
                        new FileReader(inputFile), CSV_FORMAT_ROOT_EVENT_IDS.withFirstRecordAsHeader())) {

                    // read all records into memory
                    List<CSVRecord> records = csvParser.getRecords();
                    int recordCount = records.size();

                    logger.info("Thread " + partition + ": " + recordCount + " root event ids read.");

                    int eventCount = 0;
                    final String stackOverflowUrlPrefix = "https://stackoverflow.com";

                    // iterate over records
                    for (int recordIndex = 0; recordIndex < recordCount; recordIndex++) {
                        CSVRecord record = records.get(recordIndex);
                        Integer rootEventId = Integer.parseInt(record.get("RootEventId"));

                        // log only every LOG_PACE record
                        if (recordIndex == 0 || recordIndex == recordCount - 1 || recordIndex % LOG_PACE == 0) {
                            // Locale.ROOT -> force '.' as decimal separator
                            String progress = String.format(Locale.ROOT, "%.2f%%", (((double) (recordIndex + 1)) / recordCount * 100));
                            logger.info("Thread " + partition + ": Current root event id: " + rootEventId
                                    + " (record " + (recordIndex + 1) + " of " + recordCount + "; " + progress + ")");
                        }

                        // retrieve all events for current navigation sequence in chronological order
                        String currentNavigationSequenceQuery = String.format("FROM Event " +
                                        "WHERE RootEventId='%d' ORDER BY CreationDate ASC", rootEventId
                        );

                        t = session.beginTransaction();

                        // save events in list and normalize Urls
                        List<Event> navigationSequence = session.createQuery(currentNavigationSequenceQuery, Event.class)
                                .getResultList();

                        Map<String, Event> accessedPostUrls = new HashMap<>();
                        for (int i=0; i<navigationSequence.size(); i++) {
                            Event event = navigationSequence.get(i);

                            if (event.getEventTarget().equals("Post")) {
                                // normalize links to Stack Overflow posts
                                event.setNormalizedUrl(URL.getNormalizedStackOverflowLink(
                                        stackOverflowUrlPrefix + event.getUrl())
                                        .getUrlString().substring(stackOverflowUrlPrefix.length())
                                );

                                accessedPostUrls.put(event.getUrl(), event);

                                // use previously accessed post URLs to correctly set normalized URL for truncated
                                // referrers, e.g.:
                                //   RootEventId: 271116326
                                //   Referrer: /questions/35352638/react-router-how-to
                                //   Url: /questions/35352638/react-router-how-to-get-parameter-value-from-url/48256676
                                for (Map.Entry<String, Event> accessedPostUrl : accessedPostUrls.entrySet()) {
                                    if (accessedPostUrl.getKey().startsWith(event.getReferrer())) {
                                        event.setNormalizedReferrer(accessedPostUrl.getValue().getNormalizedUrl());
                                    }
                                }
                            }

                            // detect page refreshes
                            if (i > 0) {
                                Event previousEvent = navigationSequence.get(i-1);
                                boolean pageRefresh = isPageRefresh(event, previousEvent);
                                event.setPageRefresh(pageRefresh);

                                // update first event in sequence
                                // otherwise, not all events would be marked as page refreshes in a sequence
                                // consisting exclusively of page refreshes
                                if (i == 1 && pageRefresh) {
                                    previousEvent.setPageRefresh(true);
                                    session.update(previousEvent);
                                }
                            }

                            // extract query and fragment identifier from Url
                            event.extractQuery();
                            event.extractFragmentIdentifier();

                            // update event in database
                            session.update(event);
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

    private boolean isPageRefresh(Event event, Event previousEvent) {
        return previousEvent.getEventTarget().equals(event.getEventSource())
                && previousEvent.getUrl().equals(event.getUrl())
                && previousEvent.getUrl().startsWith(event.getReferrer());
    }
}
