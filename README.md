# so-internal-refs
Scripts used to import and analyze internal web server logs provided by Stack Overflow under an NDA.

To extract navigation sequences from the event log, run:

    java -jar stint-1.1.0-jar-with-dependencies.jar -h hibernate.cfg.xml -d data
    
To further process linear navigation sequences, run:

    java -jar stint-1.1.0-jar-with-dependencies.jar -h hibernate.cfg.xml -d data -l
