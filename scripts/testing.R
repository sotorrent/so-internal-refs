# set working directory (see https://stackoverflow.com/a/35842119)
dir = tryCatch({
  # script being sourced
  getSrcDirectory()[1]
}, error = function(e) {
  # script being run in RStudio
  dirname(rstudioapi::getActiveDocumentContext()$path)
})
setwd(dir)

source("event_handlers_revised.R")
source("functions.R")

library(data.table)

################################################################################

sequences <- fread("data/NavigationSequencesComplete.csv", header=TRUE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
n <- nrow(sequences)
n
# 3,939,354

# add missing event handlers
event_target_frequency <- sort(table(sequences$EventTarget), decreasing=TRUE)
event_target_frequency
# Search x
# 2552695 
# Post x
# 1275098 
# QuestionsList x 
# 61507 
# User x
# 24360 
# Home x 
# 10263 
# UserOther x
# 7539 
# Tags x
# 5729 
# QuestionsListUnanswered x
# 822 
# HelpBadges x 
# 326 
# HelpAnswerAdvice x
# 290 
# PostHistory x
# 245 
# HelpTour x
# 199 
# Review x
# 195 
# HelpPrivileges x
# 44 
# Help x
# 25 
# Other x
# 6 
# Revision x
# 6 
# HelpAskAdvice x 
# 4 
# HelpEdit x 
# 2 

# get (up to) 10 sequences containing a certain type
test_data <- integer()
for (event_target in unique(sequences$EventTarget)) {
  print(paste0("Current event target: ", event_target))
  root_event_ids <- as.integer(unique(sequences[sequences$EventTarget == event_target,]$RootEventId))
  n <- length(root_event_ids)
  n_sample <- min(10, n)
  sample <- root_event_ids[sample(1:n, n_sample)]
  test_data <- c(test_data, sample)
}

# write test data
write.table(sequences[sequences$RootEventId %in% test_data], file="data/NavigationSequencesTestData.csv", sep=",", col.names=TRUE, row.names=FALSE, na="", quote=TRUE, qmethod="double", fileEncoding="UTF-8")

# read test data
sequences <- fread("data/NavigationSequencesTestData.csv", header=TRUE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
n <- nrow(sequences)
n
# 167

# test pattern extraction
event_sequences <- extract_navigation_patterns(sequences)
event_sequences$SequencePatternNormalized1 <- normalize_navigation_patterns_1(event_sequences$SequencePattern)
event_sequences$SequencePatternNormalized2 <- normalize_navigation_patterns_2(event_sequences$SequencePattern)

