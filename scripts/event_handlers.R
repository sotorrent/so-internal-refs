# Event handlers for pattern generation from event sequences

library(stringr)
library(urltools)

search_event_handler <- function(row) {
  if (row$EventTarget != "Search") {
    stop(paste0("Search event handler called for wrong event: ", row$EventTarget))
  }
  
  query_string <- tolower(row$Query)
  search_query <- str_replace_all(
    url_decode(str_match(query_string, "q=([^&]+)")[1,2]),
    "\\s+", " " # normalize whitespaces
  ) 
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]
  page <- str_match(query_string, "page=([^&]+)")[1,2]
  pagesize <- str_match(query_string, "pagesize=([^&]+)")[1,2]
  
  # tab can be either relevance, newest, active, or votes
  # relevance is the default value
  tab <- if (is.na(tab)) "relevance" else tab
  # first page is default 
  page <- if (is.na(page)) "1" else page
  # pagesize is previously selected one (saved in cookie), default is 15
  #pagesize <- if (is.na(pagesize)) "default" else pagesize
  
  return(paste0("Search(tab=", tab, ";page=", page, ";query=", search_query, ")"))
}

home_event_handler <- function(row) {
  if (row$EventTarget != "Home") {
    stop(paste0("Home event handler called for wrong event: ", row$EventTarget))
  }
  
  return("Home()")
}

post_event_handler <- function(row) {
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
  
  origin <- "unkown"
  if (!is.na(from_search)) {
    origin <- "searchresult"
  } 
  if (!is.na(from_related_question)) {
    origin <- "relatedquestion"
  }
  if (!is.na(from_linked_question)) {
    origin <- "linkedquestion"
  }
  
  return(paste0("Post(type=", post_type, ";id=", post_id, ";origin=", origin, ")"))
}

questionslist_event_handler <- function(row) {
  if (row$EventTarget != "QuestionsList") {
    stop(paste0("QuestionsList event handler called for wrong event: ", row$EventTarget))
  }
  
  url_string <- tolower(row$Url)
  tag <- str_match(url_string, "/questions/tagged/([^?]+)")[1,2]
  tag <- if (is.na(tag)) "none" else tag
  
  query_string <- tolower(row$Query)
  tab <- str_match(query_string, "tab=([^&]+)")[1,2]
  page <- str_match(query_string, "page=([^&]+)")[1,2]
  #pagesize <- str_match(query_string, "pagesize=([^&]+)")[1,2]
  sorting <- str_match(query_string, "sort=([^&]+)")[1,2]
  
  # newest is the default value
  tab <- if (is.na(tab)) "newest" else tab
  # first page is default 
  page <- if (is.na(page)) "1" else page
  # pagesize is previously selected one (saved in cookie), default is 15
  #pagesize <- if (is.na(pagesize)) "default" else pagesize
  # newest is default
  sorting <- if (is.na(sorting)) "newest" else sorting
  
  return(paste0("QuestionsList(tag=", tag, ";tab=", tab, ";sort=", sorting, ";page=", page, ")"))
}

tags_event_handler <- function(row) {
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
  
  return(paste0("Tags(tab=", tab, ";page=", page, ")"))
}

user_event_handler <- function(row) {
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
  
  return(paste0("User(id=", user_id, ";tab=", tab, ")"))
}

userother_event_handler <- function(row) {
  if (row$EventTarget != "UserOther") {
    stop(paste0("UserOther event handler called for wrong event: ", row$EventTarget))
  }
  
  url_string <- tolower(row$Url)
  if (url_string != "/users") {
    stop(paste0("Unkown UserOther Url: ", url_string))
  }
  
  return("UserList()")
}

help_event_handler <- function(row) {
  # update this in case other help pages are part of the sample
  
  if (row$EventTarget != "HelpPrivileges") {
    stop(paste0("Help event handler called for wrong event: ", row$EventTarget))
  }
  
  url_string <- tolower(row$Url)
  if (url_string != "/help/privileges") {
    stop(paste0("Unkown Help Url: ", url_string))
  }
  
  return("Help(topic=privileges)")
}

posthistory_event_handler <- function(row) {
  if (row$EventTarget != "PostHistory") {
    stop(paste0("PostHistory event handler called for wrong event: ", row$EventTarget))
  }
  
  url_string <- tolower(row$Url)
  post_id <- str_match(url_string, "/posts/(\\d+)")[1,2]
  if (is.na(post_id)) {
    stop(paste0("Invalid Post Url: ", url_string))
  }

  return(paste0("PostHistory(id=", post_id, ")"))
}
