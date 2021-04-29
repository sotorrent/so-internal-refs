# Event handlers for revised pattern generation from event sequences

library(stringr)
library(urltools)

Event <- setClass(
  "Event",
  slots = c(
    type = "character",
    details   = "character",
    query   = "character",
    tab = "character",
    page = "integer"
  )
)

get_search_event <- function(row, previous_event) {
  if (row$EventTarget != "Search") {
    stop(paste0("Search event handler called for wrong event: ", row$EventTarget))
  }
  
  query_string <- tolower(row$Query)
  search_query <- str_replace_all(
    url_decode(str_match(query_string, "q=([^&]+)")[1,2]),
    "\\s+", " " # normalize whitespaces
  )
  if (is.na(search_query)) {
    search_query = "" # some search queries were empty
  }
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]
  page <- str_match(query_string, "page=([^&]+)")[1,2]
  
  # tab can be either relevance, newest, active, or votes
  # relevance is the default value
  tab <- if (is.na(tab)) "relevance" else tab
  # first page is default 
  page <- if (is.na(page)) as.integer(1) else as.integer(page)

  details <- paste0("Search(tab=", tab, ";page=", page, ";query=", search_query, ")")

  event_type <- NA
  if (length(previous_event@query) == 0 || length(search_query) == 0) {
    event_type <- "Q" 
  } else {
    # check for query refinement or browsing behavior
    if (previous_event@query == search_query) {
      if (previous_event@tab != tab) {
        event_type <- "B"  # browsing through tabs
      } else if (previous_event@page != page) {
        event_type <- "B"  # browsing through pages
      } else {
        event_type <- "PageRefresh"
      }
    } else {
      # query refinement
      event_type <- "R"  
    }
  }

  event <- Event()
  event@type = event_type
  event@details = details
  event@query = search_query
  event@tab = tab
  event@page = page
  
  return(event)
}

get_home_event <- function(row) {
  if (row$EventTarget != "Home") {
    stop(paste0("Home event handler called for wrong event: ", row$EventTarget))
  }

  details <- "Home()"
  
  event <- Event()
  event@type = "H"
  event@details = details
  
  return(event)
}

get_post_event <- function(row, previous_event) {
  if (row$EventTarget != "Post") {
    stop(paste0("Post event handler called for wrong event: ", row$EventTarget))
  }

  url_string <- tolower(row$Url)
  question_id <- str_match(url_string, "/q(?:uestions)?/(\\d+)")[1,2]
  answer_id <- str_match(url_string, "/q(?:uestions)?/\\d+/[^/]+/(\\d+)")[1,2]
  if (is.na(answer_id)) {
    answer_id <- str_match(url_string, "/a/(\\d+)")[1,2]
  }

  if (is.na(question_id) & is.na(answer_id)) {
    stop(paste0("Invalid Post Url: ", url_string))
  }

  post_type <- if (!is.na(answer_id)) "a" else "q"
  post_id <- if (!is.na(answer_id)) answer_id else question_id

  query_string <- tolower(row$Query)
  from_search <- str_match(query_string, "s=([^&]+)")[1,2]
  from_related_question <- str_match(query_string, "rq=([^&]+)")[1,2]
  from_linked_question <- str_match(query_string, "lq=([^&]+)")[1,2]

  # default values, any case where we don't have explicit evidence of following a link is considered P (and not F)
  origin <- "unkown"
  event_type <- "P"
    
  #if (length(previous_event@type) == 0) {
  #  event_type <- "P" # first event in sequence
  #} else {
  #  event_type <- "F"
  #}
  
  if (!is.na(from_search)) {
    origin <- "searchresult"
    event_type <- "S"  # coming from search results
  }
  if (!is.na(from_related_question)) {
    origin <- "relatedquestion"
    event_type <- "X" # coming from related question
  }
  if (!is.na(from_linked_question)) {
    origin <- "linkedquestion"
    event_type <- "X" # coming from linked question
  }

  details <- paste0("Post(type=", post_type, ";id=", post_id, ";origin=", origin, ")")
  
  event <- Event()
  event@type = event_type
  event@details = details

  return(event)
}

get_questionslist_event <- function(row) {
  if (row$EventTarget != "QuestionsList" && row$EventTarget != "QuestionsListUnanswered") {
    stop(paste0("QuestionsList event handler called for wrong event: ", row$EventTarget))
  }

  url_string <- tolower(row$Url)
  tag <- str_match(url_string, "/(?:questions|unanswered)/tagged/([^?]+)")[1,2]
  tag <- if (is.na(tag)) "none" else tag

  query_string <- tolower(row$Query)
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]
  page <- str_match(query_string, "page=([^&]+)")[1,2]
  sorting <- str_match(query_string, "sort=([^&]+)")[1,2]

  # newest is the default value
  tab <- if (is.na(tab)) "newest" else tab
  # first page is default
  page <- if (is.na(page)) "1" else page
  # newest is default
  sorting <- if (is.na(sorting)) "newest" else sorting

  details <- paste0(row$EventTarget, "(tag=", tag, ";tab=", tab, ";sort=", sorting, ";page=", page, ")")
  
  event <- Event()
  event@type = "L"
  event@details = details

  return(event)
}

get_tags_event <- function(row) {
  if (row$EventTarget != "Tags") {
    stop(paste0("Tags event handler called for wrong event: ", row$EventTarget))
  }

  query_string <- tolower(row$Query)
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]
  page <- str_match(query_string, "page=([^&]+)")[1,2]

  # popular is the default value
  tab <- if (is.na(tab)) "popular" else tab
  # first page is default
  page <- if (is.na(page)) "1" else page

  details <- paste0("Tags(tab=", tab, ";page=", page, ")")
  
  event <- Event()
  event@type = "T"
  event@details = details

  return(event)
}

get_user_event <- function(row) {
  if (row$EventTarget != "User") {
    stop(paste0("User event handler called for wrong event: ", row$EventTarget))
  }

  url_string <- tolower(row$Url)
  user_id <- str_match(url_string, "/users/(\\d+)")[1,2]

  if (is.na(user_id)) {
    stop(paste0("Invalid User Url: ", url_string))
  }

  query_string <- tolower(row$Query)
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]

  # profile is the default value
  tab <- if (is.na(tab)) "profile" else tab

  details <- paste0("User(id=", user_id, ";tab=", tab, ")")
  
  event <- Event()
  event@type = "U"
  event@details = details
  
  return(event)
}

get_userother_event <- function(row) {
  if (row$EventTarget != "UserOther") {
    stop(paste0("UserOther event handler called for wrong event: ", row$EventTarget))
  }

  url_string <- tolower(row$Url)
  if (!startsWith(url_string, "/users")) {
    stop(paste0("Unkown UserOther Url: ", url_string))
  }

  details <- "UserList()"
  
  event <- Event()
  event@type = "U"
  event@details = details
  
  return(event)
}

get_help_event <- function(row) {
  # update this in case other help pages are part of the sample

  if (!row$EventTarget %in% c("Help", "HelpPrivileges", "HelpBadges", "HelpAnswerAdvice", "HelpPrivileges", "HelpAskAdvice", "HelpEdit", "HelpTour")) {
    stop(paste0("Help event handler called for wrong event: ", row$EventTarget))
  }

  topic <- tolower(gsub("Help", "", row$EventTarget, perl=TRUE))
  details <- paste0("Help(topic=", topic, ")")
  
  event <- Event()
  event@type = "O"
  event@details = details
  
  return(event)
}

get_posthistory_event <- function(row) {
  if (row$EventTarget != "PostHistory") {
    stop(paste0("PostHistory event handler called for wrong event: ", row$EventTarget))
  }

  url_string <- tolower(row$Url)
  post_id <- str_match(url_string, "/posts/(\\d+)")[1,2]
  if (is.na(post_id)) {
    stop(paste0("Invalid Post Url: ", url_string))
  }

  details <- paste0("PostHistory(id=", post_id, ")")

  event <- Event()
  event@type = "O"
  event@details = details
  
  return(event)
}

get_other_event <- function(row) {
  details <- paste0("Other()")
  
  event <- Event()
  event@type = "O"
  event@details = details
  
  return(event)
}
