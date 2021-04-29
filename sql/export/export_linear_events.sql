USE `sointernalrefs`;

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
INTO OUTFILE 'F:/Temp/LinearEvent.csv' 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Event`
WHERE RootEventId IN (
	SELECT RootEventId
	FROM sointernalrefs.LinearNonBotNonPageRefreshSequences
);
