DROP DATABASE IF EXISTS `sointernalrefs`;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `sointernalrefs` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;

USE `sointernalrefs`;

DROP TABLE IF EXISTS `LinearSearchThreadEvent`;
CREATE TABLE `LinearSearchThreadEvent` (
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
  PRIMARY KEY (Id)
);

SET autocommit = 0;
SET foreign_key_checks = 0;
SET unique_checks = 0;
SET sql_log_bin = 0;

LOAD DATA INFILE 'F:/Temp/LinearSearchThreadEvent.csv'
INTO TABLE `LinearSearchThreadEvent`
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
  @FragmentIdentifier )
SET RootEventId = nullif(@RootEventId, ''),
  DiffSeconds = nullif(@DiffSeconds, ''),
  Query = nullif(@Query, ''),
  FragmentIdentifier = nullif(@FragmentIdentifier, '');
COMMIT;

SET autocommit = 1;
SET foreign_key_checks = 1;
SET unique_checks = 1;
SET sql_log_bin = 1;

CREATE INDEX `linear_search_thread_event_index_1` ON LinearSearchThreadEvent(UserIdentifier);
CREATE INDEX `linear_search_thread_event_index_2` ON LinearSearchThreadEvent(CreationDate);
CREATE INDEX `linear_search_thread_event_index_3` ON LinearSearchThreadEvent(EventSource);
CREATE INDEX `linear_search_thread_event_index_4` ON LinearSearchThreadEvent(EventTarget);
CREATE INDEX `linear_search_thread_event_index_5` ON LinearSearchThreadEvent(DiffSeconds);
CREATE INDEX `linear_search_thread_event_index_6` ON LinearSearchThreadEvent(RootEventId);
