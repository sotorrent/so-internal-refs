library(stringr)

# Helper functions for visual data analysis

plot_data <- function(t, min_value, max_value) {
  x <- min_value:max_value
  y <- t[(min_value-1):(max_value-1)]
  plot(x, y, pch=16)
  lines(x, y)  
}

get_slope <- function(t, min_value, max_value) {
  x <- min_value:max_value
  y <- t[(min_value-1):(max_value-1)]
  m <- numeric(length = (length(x)-1))
  m_diff <- as.numeric(rep(0, (length(x)-1)))
  for (i in 1:length(m)) {
    x_0 <- x[i]
    x_1 <- x[i+1]
    y_0 <- y[i]
    y_1 <- y[i+1]
    m[i] <- (y_1-y_0)/(x_1-x_0)
    names(m)[i] <- paste0("(", i+1, ",", i+2, ")")
    if (i>1) {
      m_diff[i]= m[i-1]-m[i]
    }
  }
  df <- data.frame(slope=m, slope_diff=m_diff)
  row.names(df) <- names(m)
  return(df)
}

extract_navigation_patterns <- function(sequences) {
  print("Extracting navigation patterns...")
  
  root_event_ids <- unique(sequences$RootEventId)
  n <- length(root_event_ids)
  
  event_sequences <- data.frame(
    root_event_ids,
    rep("", length(root_event_ids)),
    rep("", length(root_event_ids)),
    stringsAsFactors=FALSE
  )
  names(event_sequences) <- c("RootEventId", "SequencePattern", "SequenceDetails")
  
  count <- as.integer(0)
  for (root_event_id in root_event_ids) {
    rows <- sequences[sequences$RootEventId == root_event_id]
    count <- count + 1
    
    sequence_pattern <- character(0)
    sequence_details <- character(0)
    
    event_history <- list(rep(NA, nrow(rows)))
    for (i in 1:nrow(rows)) {
      event_history[[i]] <- Event()
    }
    
    if (count %% 10 == 0) {
      progress <- as.numeric(count/n*100)
      print(paste0("Progress: ", format(round(progress, 2), nsmall=2), "%"))      
    }

    print(paste0("RootEventId: ", root_event_id))
    
    for (i in 1:nrow(rows)) {
      current_row <- rows[i]
      current_event <- Event()
      previous_event <- Event()
      if (i > 1) {
        previous_event <- event_history[[i-1]]   
      }
      
      switch(current_row$EventTarget, 
             Search={current_event <- get_search_event(current_row, previous_event)},
             Post={current_event <- get_post_event(current_row, previous_event)},
             QuestionsList={current_event <- get_questionslist_event(current_row)},
             QuestionsListUnanswered={current_event <- get_questionslist_event(current_row)},
             User={current_event <- get_user_event(current_row)},
             UserOther={current_event <- get_userother_event(current_row)},
             Home={current_event <- get_home_event(current_row)},
             Tags={current_event <- get_tags_event(current_row)},
             HelpBadges={current_event <- get_help_event(current_row)}, 
             HelpAnswerAdvice={current_event <- get_help_event(current_row)}, 
             HelpTour={current_event <- get_help_event(current_row)}, 
             HelpPrivileges={current_event <- get_help_event(current_row)}, 
             Help={current_event <- get_help_event(current_row)}, 
             HelpAskAdvice={current_event <- get_help_event(current_row)}, 
             HelpEdit={current_event <- get_help_event(current_row)}, 
             HelpPrivileges={current_event <- get_help_event(current_row)},
             PostHistory={current_event <- get_posthistory_event(current_row)},
             Review={current_event <- get_other_event(current_row)},
             Other={current_event <- get_other_event(current_row)},
             Revision={current_event <- get_other_event(current_row)}
      )
      
      if (length(current_event@type) == 0) {
        stop(paste0("Unknown EventTarget: ", current_row$EventTarget))
      }
      
      # ignore page refresh
      if (current_event@type == "PageRefresh"  # detected in one of the event handlers
          || (length(current_event@details) > 0 && length(previous_event@details) > 0 && (current_event@details == previous_event@details))) {
        print(paste0("Event ignored: ", current_event@type))
        # replace ignored event in event history
        event_history[[i]] <- previous_event
      } else {
        print(paste0("Event: ", current_event@type))
        event_history[[i]] <- current_event 
        if (length(sequence_pattern) == 0) {
          sequence_pattern  <- current_event@type
          sequence_details <- current_event@details
        } else {
          sequence_pattern <- paste0(sequence_pattern, current_event@type)
          sequence_details <- paste0(sequence_details, "\n", current_event@details)
        } 
      }
    }
    
    event_sequences[event_sequences$RootEventId == root_event_id, 2] <- sequence_pattern
    event_sequences[event_sequences$RootEventId == root_event_id, 3] <- sequence_details
  }
  
  return(event_sequences)
}

events <- c("Q", "B", "R", "H", "P", "S", "X", "L", "U", "O", "T")

normalize_navigation_patterns_1 <- function(sequence_patterns) {
  print("Normalizing navigation patterns (1)...")
  sequence_patterns_normalized <- sequence_patterns
  for (event in events) {
    print(paste0("Processing ", event, "..."))
    pattern <- paste0(event, "+")
    sequence_patterns_normalized <- gsub(pattern, event, sequence_patterns_normalized, perl=TRUE)
  }
 return(sequence_patterns_normalized) 
}

normalize_navigation_patterns_2 <- function(sequence_patterns) {
  print("Normalizing navigation patterns (2)...")
  sequence_patterns_normalized <- sequence_patterns
  for (event in events) {
    print(paste0("Processing ", event, "..."))
    pattern <- paste0(event, "+")
    sequence_patterns_normalized <- gsub("P|S|X", "P", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub("U|O|T", "O", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub(pattern, event, sequence_patterns_normalized, perl=TRUE)
  }
  return(sequence_patterns_normalized) 
}

normalize_navigation_patterns_2 <- function(sequence_patterns) {
  print("Normalizing navigation patterns (2)...")
  sequence_patterns_normalized <- sequence_patterns
  for (event in events) {
    print(paste0("Processing ", event, "..."))
    pattern <- paste0(event, "+")
    sequence_patterns_normalized <- gsub("P|S|X", "P", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub("U|O|T", "O", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub(pattern, event, sequence_patterns_normalized, perl=TRUE)
  }
  return(sequence_patterns_normalized) 
}

normalize_navigation_patterns_3 <- function(sequence_patterns) {
  print("Normalizing navigation patterns (3)...")
  sequence_patterns_normalized <- sequence_patterns
  for (event in events) {
    print(paste0("Processing ", event, "..."))
    pattern <- paste0(event, "+")
    # only consilder Q/R, B, and P/S/X events for the patterns
    sequence_patterns_normalized <- gsub("P|S|X", "P", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub("O|H|L|U|T", "O", sequence_patterns_normalized, perl=TRUE)
    sequence_patterns_normalized <- gsub(pattern, event, sequence_patterns_normalized, perl=TRUE)
  }
  sequence_patterns_normalized[grepl("O", sequence_patterns_normalized, perl=TRUE)] <- NA
  sequence_patterns_normalized[!startsWith(sequence_patterns_normalized, "Q")] <- NA
  sequence_patterns_normalized[!endsWith(sequence_patterns_normalized, "P")] <- NA
  return(sequence_patterns_normalized) 
}

assign_groups <- function(sequence_frequency) {
  sequence_frequency$Group <- as.character(rep(NA, nrow(sequence_frequency)))
  
  # order of execution is important, because some patterns overwrite previously defined ones
  
  description = "sequences containing excluded events"
  filter <- is.na(sequence_frequency$SequencePatternNormalized)
  sequence_frequency[filter,]$Group <- rep(description, length(which(filter)))
  
  regex = "^Q(P|Q|R|B)+P$"
  filter <- grepl(regex, sequence_frequency$SequencePatternNormalized, perl=TRUE)
  
  q_count <- str_count(sequence_frequency$SequencePatternNormalized, pattern="Q")
  q_filter <- q_count > 1
  r_count <- str_count(sequence_frequency$SequencePatternNormalized, pattern="R")
  r_filter <- r_count > 0
  
  filter_combined <- filter & q_filter & r_filter
  description = "requery, query refinement"
  sequence_frequency[filter_combined,]$Group <- rep(description, length(which(filter_combined)))
  
  filter_combined <- filter & q_filter & !r_filter
  description = "requery, no query refinement"
  sequence_frequency[filter_combined,]$Group <- rep(description, length(which(filter_combined)))
  
  filter_combined <- filter & !q_filter & r_filter
  description = "no requery, query refinement"
  sequence_frequency[filter_combined,]$Group <- rep(description, length(which(filter_combined)))
  
  filter_combined <- filter & !q_filter & !r_filter
  description = "no requery, no query refinement"
  sequence_frequency[filter_combined,]$Group <- rep(description, length(which(filter_combined)))
  
  regex = "^QB*P$"
  description = "single query, browsing"
  filter <- grepl(regex, sequence_frequency$SequencePatternNormalized, perl=TRUE)
  sequence_frequency[filter,]$Group <- rep(description, length(which(filter)))
  
  return(sequence_frequency)
}
