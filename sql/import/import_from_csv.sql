DROP DATABASE IF EXISTS `sointernalrefs`;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `sointernalrefs` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;

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
) AUTO_INCREMENT = 1;

SET autocommit = 0;
SET foreign_key_checks = 0;
SET unique_checks = 0;
SET sql_log_bin = 0;

LOAD DATA INFILE 'F:/Temp/InternalRefs.csv'
INTO TABLE `Event`
FIELDS OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@CreationDate, @Url, @Referrer, @UserIdentifier, @EventTarget, @EventSource)
SET CreationDate = FROM_UNIXTIME(@CreationDate),
	Url = @Url,
  Referrer = @Referrer,
  UserIdentifier = @UserIdentifier,
  EventTarget = nullif(@EventTarget, ''),
  EventSource = nullif(@EventSource, '');
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

# replace NULL values in column EventSource
UPDATE `Event`
SET EventSource = CASE
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?(?:q|a)\/[[:digit:]]+') THEN "Question"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?jobs') THEN "Job"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?posts\/[[:digit:]]+\/edit') THEN "PostEdit"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?feeds') THEN "Feeds"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?cv') THEN "CV"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?(?:#|\/$)') THEN "Home"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?legal') THEN "Legal"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?election') THEN "Elections"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?(?:pricing|enterprise|teams)') THEN "Commercial"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?story') THEN "DeveloperStory"
  WHEN REGEXP_LIKE(Referrer, '^[[:space:]]*\/?revisions') THEN "Revisions"
  ELSE "Other"
END
WHERE EventSource IS NULL;

# Simplify event types
UPDATE `Event`
SET EventSource = CASE
  WHEN EventSource = "Question" OR EventSource = "QuestionTiny" OR EventSource = "AnswerTiny" THEN "Post"
  WHEN EventSource = "Users" THEN "UserProfile"
  WHEN EventSource = "UsersList" OR EventSource = "UserStory" OR EventSource = "DeveloperStory" OR EventSource = "CV"  THEN "UserOther"
  WHEN EventSource = "Other" OR EventSource = "Job" OR EventSource = "Legal" OR EventSource = "Commercial" OR EventSource = "CompanyAbout" OR EventSource = "Feeds" OR EventSource = "Elections" OR EventSource = "SalaryCalculator" OR EventSource = "SalarySkills" THEN "Other"
  WHEN EventSource = "TagsList" OR EventSource = "NewTags" OR EventSource = "HotTags" THEN "Tags"
  WHEN EventSource = "Tour" THEN "HelpTour"
  WHEN EventSource = "Privilege" OR EventSource = "PrivilegesList" THEN "HelpPrivileges"
  WHEN EventSource = "Badge" OR EventSource = "BadgeList" THEN "HelpBadges"
  WHEN EventSource = "AnswerAdvice" THEN "HelpAnswerAdvice"
  WHEN EventSource = "AskAdvice" THEN "HelpAskAdvice"
  WHEN EventSource = "EditHelp" THEN "HelpEdit"
  WHEN EventSource = "Faq" THEN "HelpFaq"
  WHEN EventSource = "Revisions" OR EventSource = "PostTimeline" OR EventSource = "RevisionsList" THEN "PostHistory"
  WHEN EventSource = "ReviewDashboard" OR EventSource = "ReviewTask" THEN "Review"
  WHEN EventSource = "QuestionsList" OR EventSource = "QuestionsListByTag" OR EventSource = "QuestionsListByLinked" THEN "QuestionsList"
  WHEN EventSource = "UnansweredQuestionsList" OR EventSource = "UnansweredQuestionsListByTag" THEN "QuestionsListUnanswered"
  ELSE EventSource
END;

UPDATE `Event`
SET EventTarget = CASE
  WHEN EventTarget = "Question" OR EventTarget = "QuestionTiny" OR EventTarget = "AnswerTiny" THEN "Post"
  WHEN EventTarget = "Users" THEN "UserProfile"
  WHEN EventTarget = "UsersList" OR EventTarget = "UserStory" OR EventTarget = "DeveloperStory" OR EventTarget = "CV"  THEN "UserOther"
  WHEN EventTarget = "Other" OR EventTarget = "Job" OR EventTarget = "Legal" OR EventTarget = "Commercial" OR EventTarget = "CompanyAbout" OR EventTarget = "Feeds" OR EventTarget = "Election" OR EventTarget = "SalaryCalculator" OR EventTarget = "SalarySkills" THEN "Other" 
  WHEN EventTarget = "TagsList" OR EventTarget = "NewTags" OR EventTarget = "HotTags" THEN "Tags"
  WHEN EventTarget = "Tour" THEN "HelpTour"
  WHEN EventTarget = "Privilege" OR EventTarget = "PrivilegesList" THEN "HelpPrivileges"
  WHEN EventTarget = "Badge" OR EventTarget = "BadgeList" THEN "HelpBadges"
  WHEN EventTarget = "AnswerAdvice" THEN "HelpAnswerAdvice"
  WHEN EventTarget = "AskAdvice" THEN "HelpAskAdvice"
  WHEN EventTarget = "EditHelp" THEN "HelpEdit"
  WHEN EventTarget = "Faq" THEN "HelpFaq"
  WHEN EventTarget = "Revisions" OR EventTarget = "PostTimeline" OR EventTarget = "RevisionsList" THEN "PostHistory"
  WHEN EventTarget = "ReviewDashboard" OR EventTarget = "ReviewTask" THEN "Review"
  WHEN EventTarget = "QuestionsList" OR EventTarget = "QuestionsListByTag" OR EventTarget = "QuestionsListByLinked" THEN "QuestionsList"
  WHEN EventTarget = "UnansweredQuestionsList" OR EventTarget = "UnansweredQuestionsListByTag" THEN "QuestionsListUnanswered"
  ELSE EventTarget
END;

###########################################################
# run navigation sequence extraction (EventIterator.java) #
###########################################################

CREATE INDEX `event_index_6` ON Event(DiffSeconds);
CREATE INDEX `event_index_7` ON Event(RootEventId);
CREATE INDEX `event_index_8` ON Event(BotTraffic);
CREATE INDEX `event_index_9` ON Event(GapInSequence);
CREATE INDEX `event_index_10` ON Event(PageRefresh);

DROP TABLE IF EXISTS `PossibleBots`;
CREATE TABLE `PossibleBots` (
  UserIdentifier VARCHAR(16) DEFAULT NULL
);
INSERT INTO PossibleBots
SELECT DISTINCT UserIdentifier
FROM Event
WHERE BotTraffic = TRUE;
ALTER TABLE PossibleBots ADD PRIMARY KEY(UserIdentifier);

DROP TABLE IF EXISTS `NonLinearSequences`;
CREATE TABLE `NonLinearSequences` (
  RootEventId VARCHAR(16) DEFAULT NULL
);
INSERT INTO NonLinearSequences
SELECT DISTINCT RootEventId
FROM Event
WHERE RootEventId IS NOT NULL AND GapInSequence = TRUE;
ALTER TABLE NonLinearSequences ADD PRIMARY KEY(RootEventId);

DROP TABLE IF EXISTS `LinearNonBotSequences`;
CREATE TABLE `LinearNonBotSequences` (
  RootEventId VARCHAR(16) DEFAULT NULL
);
INSERT INTO LinearNonBotSequences
SELECT DISTINCT RootEventId
FROM Event
WHERE RootEventId IS NOT NULL
AND UserIdentifier NOT IN (
  SELECT UserIdentifier FROM PossibleBots
);
DELETE FROM LinearNonBotSequences
WHERE RootEventId IN (
  SELECT RootEventId FROM NonLinearSequences
);
ALTER TABLE LinearNonBotSequences ADD PRIMARY KEY(RootEventId);

DROP TABLE IF EXISTS `LinearNonBotNonPageRefreshSequences`;
CREATE TABLE `LinearNonBotNonPageRefreshSequences` (
  RootEventId VARCHAR(16) DEFAULT NULL
);
INSERT INTO LinearNonBotNonPageRefreshSequences
SELECT DISTINCT ls.RootEventId
FROM LinearNonBotSequences ls
JOIN Event e
ON ls.RootEventId = e.RootEventId
WHERE PageRefresh = 0;
ALTER TABLE LinearNonBotNonPageRefreshSequences ADD PRIMARY KEY(RootEventId);