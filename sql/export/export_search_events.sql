USE `sointernalrefs`;

DROP TABLE IF EXISTS `SearchSequences`;
CREATE TABLE `SearchSequences` (
  RootEventId VARCHAR(16) DEFAULT NULL
);
INSERT INTO SearchSequences
SELECT DISTINCT RootEventId
FROM Event
WHERE EventTarget = "Search";
CREATE INDEX `searchsequences_index_1` ON SearchSequences(RootEventId);

SELECT
  Id,
  IFNULL(RootEventId, ''),
  UserIdentifier,
  CreationDate,
  IFNULL(DiffSeconds, ''),
  EventSource,
  EventTarget,
  Referrer,
  Url,
  IFNULL(Query, ''),
  IFNULL(FragmentIdentifier, '')
INTO OUTFILE 'F:/Temp/LinearSearchEvent.csv' 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Event`
WHERE RootEventId IN (
	SELECT search_sequences.RootEventId AS RootEventId
	FROM sointernalrefs.SearchSequences search_sequences
	JOIN sointernalrefs.LinearNonBotNonPageRefreshSequences linear_sequences
	ON search_sequences.RootEventId = linear_sequences.RootEventId
);
