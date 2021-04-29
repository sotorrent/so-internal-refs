package org.sotorrent.stint;

import org.apache.commons.cli.*;

import java.nio.file.Path;
import java.nio.file.Paths;

public class Main {
    public static void main (String[] args) {
        System.out.println("Stint");

        Options options = new Options();

        Option dataDirOption = new Option("d", "data-dir", true,
                "path to data directory (used to store temporary data)");
        dataDirOption.setRequired(true);
        options.addOption(dataDirOption);

        Option hibernateConfigFileOption = new Option("h", "hibernate-config", true,
                "path to hibernate config file");
        hibernateConfigFileOption.setRequired(true);
        options.addOption(hibernateConfigFileOption);

        Option partitionCountOption = new Option("p", "partition-count", true,
                "number of partitions created for parallel processing (one worker thread per partition, default value: 4)");
        partitionCountOption.setRequired(false);
        options.addOption(partitionCountOption);

        Option skipUserIdentifierRetrievalOption = new Option("s", "skip-retrieval", false,
                "skip retrieval and splitting of input data (if set, temporary CSV files are expected in data directory)");
        skipUserIdentifierRetrievalOption.setRequired(false);
        options.addOption(skipUserIdentifierRetrievalOption);

        Option processLinearSequencesOption = new Option("l", "process-linear", false,
                "only process linear sequences");
        processLinearSequencesOption.setRequired(false);
        options.addOption(processLinearSequencesOption);

        CommandLineParser commandLineParser = new DefaultParser();
        HelpFormatter commandLineFormatter = new HelpFormatter();
        CommandLine commandLine;

        try {
            commandLine = commandLineParser.parse(options, args);
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            commandLineFormatter.printHelp("Stint", options);
            System.exit(1);
            return;
        }

        Path dataDirPath = Paths.get(commandLine.getOptionValue("data-dir"));
        Path hibernateConfigFilePath = Paths.get(commandLine.getOptionValue("hibernate-config"));
        int partitionCount = 4;
        boolean skipRetrieval = false;
        boolean processLinear = false;

        if (commandLine.hasOption("partition-count")) {
            partitionCount = Integer.parseInt(commandLine.getOptionValue("partition-count"));
        }

        if (commandLine.hasOption("skip-retrieval")) {
            skipRetrieval = true;
        }

        if (commandLine.hasOption("process-linear")) {
            processLinear = true;
        }

        if (processLinear) {
            LinearSequenceIterator.createSessionFactory(hibernateConfigFilePath);
            LinearSequenceIterator linearSequenceIterator = new LinearSequenceIterator(dataDirPath, partitionCount);
            if (!skipRetrieval) {
                linearSequenceIterator.extractSaveAndSplitLinearNavigationSequences();
            }
            linearSequenceIterator.processLinearNavigationSequences();
            LinearSequenceIterator.sessionFactory.close();

        } else {
            EventIterator.createSessionFactory(hibernateConfigFilePath);
            EventIterator eventIterator = new EventIterator(dataDirPath, partitionCount);
            if (!skipRetrieval) {
                eventIterator.extractSaveAndSplitUserIdentifiers();
            }
            eventIterator.processEvents();
            EventIterator.sessionFactory.close();
        }
    }
}
