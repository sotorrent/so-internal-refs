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
  IFNULL(FragmentIdentifier, ''),
  IFNULL(NormalizedReferrer, ''),
  IFNULL(NormalizedUrl, ''),  
  BotTraffic,
  GapInSequence,
  PageRefresh
INTO OUTFILE 'F:/Temp/Event.csv' 
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Event`;
