USE `sointernalrefs`;

SELECT COUNT(*) FROM Events;
# 747,421,780

SELECT MIN(CreationDate) FROM Events;
# 2017-12-01 01:00:08

SELECT MAX(CreationDate) FROM Events;
# 2018-12-01 00:59:59

# export time differences between succeeding events
SELECT DiffMinutes
INTO OUTFILE 'F:/Temp/DiffMinutes.csv'
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM `Events`
WHERE DiffMinutes IS NOT NULL;

SELECT COUNT(DISTINCT UserIdentifier) FROM Event;
# 187,142,541

# user identifiers that may be bots
SELECT COUNT(*) FROM PossibleBots;
# 1,255,057 (0.67%)

SELECT COUNT(DISTINCT RootEventId) FROM Event;
# 98,495,404

# number of sequences produced by possible bots
SELECT COUNT(DISTINCT RootEventId) FROM Event
WHERE UserIdentifier IN (SELECT UserIdentifier FROM PossibleBots);
# 31,262,516 (31.74%)

# non-linear sequences
SELECT COUNT(DISTINCT RootEventId) FROM NonLinearSequences;
# 74,613,186 (75.75%)

# linear non-bot sequences
SELECT COUNT(DISTINCT RootEventId) FROM LinearNonBotSequences;
# 18,269,793 (18.55%)

# export length of navigation sequences (possible bots and non-linear sequences excluded)
SELECT COUNT(*)
INTO OUTFILE 'F:/Temp/NavigationSequencesLengthFiltered1.csv'
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
FROM Event
WHERE RootEventId IS NOT NULL
AND RootEventId IN(
  SELECT RootEventId FROM LinearNonBotSequences
)
GROUP BY UserIdentifier, RootEventId;

# page refreshes excluded
SELECT COUNT(DISTINCT RootEventId) FROM LinearNonBotNonPageRefreshSequences;
# 16,164,506 (88.48% of LinearNonBotSequences)

# sequences containing search event
DROP TABLE IF EXISTS `LinearSearchSequences`;
CREATE TABLE `LinearSearchSequences` (
  RootEventId INT NOT NULL,
  UNIQUE(RootEventId)
);
INSERT INTO LinearSearchSequences
SELECT DISTINCT events.RootEventId AS RootEventId
FROM Event events
JOIN LinearNonBotNonPageRefreshSequences linear_sequences
ON events.RootEventId = linear_sequences.RootEventId
WHERE EventTarget = "Search";

# sequences ending in a thread
DROP TABLE IF EXISTS `LinearThreadSequences`;
CREATE TABLE `LinearThreadSequences` (
  RootEventId INT NOT NULL,
  UNIQUE(RootEventId)
);
INSERT INTO LinearThreadSequences
SELECT DISTINCT events.RootEventId AS RootEventId
FROM Event events
JOIN (
  SELECT events_inner.RootEventId as RootEventId, MAX(CreationDate) AS MaxCreationDate 
  FROM Event events_inner
  JOIN LinearNonBotNonPageRefreshSequences linear_sequences
  ON events_inner.RootEventId = linear_sequences.RootEventId
  GROUP BY RootEventId
) last_events
ON events.RootEventId = last_events.RootEventId
  AND events.CreationDate = last_events.MaxCreationDate
WHERE EventTarget = "Post";

# sequences containing search event and ending in thread
DROP TABLE IF EXISTS `LinearSearchThreadSequences`;
CREATE TABLE `LinearSearchThreadSequences` (
  RootEventId INT NOT NULL,
  UNIQUE(RootEventId)
);
INSERT INTO LinearSearchThreadSequences
SELECT search_sequences.RootEventId AS RootEventId
FROM LinearSearchSequences search_sequences
JOIN LinearThreadSequences thread_sequences
ON search_sequences.RootEventId = thread_sequences.RootEventId;
