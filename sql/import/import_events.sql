USE `sointernalrefs`;

DROP TABLE IF EXISTS `Event`;
CREATE TABLE `Event` (
  Id INT NOT NULL AUTO_INCREMENT,
  RootEventId INT DEFAULT NULL,
  UserIdentifier VARCHAR(16) DEFAULT NULL,
  CreationDate DATETIME DEFAULT NULL,
  DiffSeconds BIGINT DEFAULT NULL,
  EventSource VARCHAR(48) DEFAULT NULL,
  EventTarget VARCHAR(48) DEFAULT NULL,
  Referrer TEXT DEFAULT NULL,
  Url TEXT DEFAULT NULL,
  Query TEXT DEFAULT NULL,
  FragmentIdentifier TEXT DEFAULT NULL,
  NormalizedReferrer TEXT DEFAULT NULL,
  NormalizedUrl TEXT DEFAULT NULL,
  BotTraffic BOOLEAN DEFAULT FALSE,
  GapInSequence BOOLEAN DEFAULT FALSE,
  PageRefresh BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (Id)
);

SET autocommit = 0;
SET foreign_key_checks = 0;
SET unique_checks = 0;
SET sql_log_bin = 0;

LOAD DATA INFILE 'F:/Temp/Event.csv'
INTO TABLE `Event`
FIELDS OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 0 ROWS
( Id,
  @RootEventId,
  UserIdentifier,
  CreationDate,
  @DiffSeconds,
  EventSource,
  EventTarget,
  Referrer,
  Url,
  @Query,
  @FragmentIdentifier,
  @NormalizedReferrer,
  @NormalizedUrl,
  BotTraffic,
  GapInSequence,
  PageRefresh)
SET RootEventId = nullif(@RootEventId, ''),
  DiffSeconds = nullif(@DiffSeconds, ''),
  Query = nullif(@Query, ''),
  FragmentIdentifier = nullif(@FragmentIdentifier, ''),
  NormalizedReferrer = nullif(@NormalizedReferrer, ''),
  NormalizedUrl = nullif(@NormalizedUrl, '');
COMMIT;

SET autocommit = 1;
SET foreign_key_checks = 1;
SET unique_checks = 1;
SET sql_log_bin = 1;

CREATE INDEX `event_index_1` ON Event(UserIdentifier);
CREATE INDEX `event_index_2` ON Event(CreationDate);
CREATE INDEX `event_index_3` ON Event(EventSource);
CREATE INDEX `event_index_4` ON Event(EventTarget);
# https://dev.mysql.com/doc/refman/8.0/en/group-by-optimization.html
# https://dev.mysql.com/doc/refman/8.0/en/multiple-column-indexes.html
CREATE INDEX `event_index_5` ON Event(UserIdentifier, CreationDate);

CREATE INDEX `event_index_6` ON Event(DiffSeconds);
CREATE INDEX `event_index_7` ON Event(RootEventId);
CREATE INDEX `event_index_8` ON Event(BotTraffic);
CREATE INDEX `event_index_9` ON Event(GapInSequence);
CREATE INDEX `event_index_10` ON Event(PageRefresh);
