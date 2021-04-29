USE `sointernalrefs`;

# export sample
DROP TABLE IF EXISTS `SampleExport`;
CREATE TABLE `SampleExport` (
  RootEventId INT NOT NULL
);
INSERT INTO SampleExport
SELECT RootEventId
FROM LinearSearchThreadSequences
ORDER BY RAND()
LIMIT 50;

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
INTO OUTFILE 'F:/Temp/LinearSearchThreadEvent.csv' 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Event`
WHERE RootEventId IN (
	SELECT RootEventId
	FROM SampleExport
)
ORDER BY RootEventId, CreationDate;

# export all sequences
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
INTO OUTFILE 'F:/Temp/LinearSearchThreadEvent.csv' 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Event`
WHERE RootEventId IN (
  SELECT RootEventId
  FROM LinearSearchThreadSequences
)
ORDER BY RootEventId, CreationDate;
