# set working directory (see https://stackoverflow.com/a/35842119)
dir = tryCatch({
  # script being sourced
  getSrcDirectory()[1]
}, error = function(e) {
  # script being run in RStudio
  dirname(rstudioapi::getActiveDocumentContext()$path)
})
setwd(dir)

source("colors.R")
source("outlier.R")
source("functions.R")
source("event_handlers.R")
source("event_handlers_revised.R")

library(data.table)

################################################################################

# read time difference between events in minutes
diff_minutes <- fread("data/DiffMinutes.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
diff_minutes <- diff_minutes$V1
n <- length(diff_minutes)
n
# 560,279,239

summary(diff_minutes)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#    0       0       0    4204      19  525245

quantile(diff_minutes, seq(0.5, 1.0, 0.05))
# 50%    55%    60%    65%    70%    75%    80%    85%    90%    95%   100% 
#   0      0      1      2      6     19    104   1129   4825  20107 525245 

quantile(diff_minutes, seq(0.6, 0.7, 0.01))
# 60% 61% 62% 63% 64% 65% 66% 67% 68% 69% 70% 
#   1   1   1   1   2   2   2   3   4   4   6 

quantile(diff_minutes, seq(0.7, 0.8, 0.01))
# 70% 71% 72% 73% 74% 75% 76% 77% 78% 79% 80% 
#   6   7   9  11  15  19  26  35  50  71 104

n_0 <- length(diff_minutes[diff_minutes==0])
n_0
# 325,724,001
n_0/n*100
# 58.13601

n_2 <- length(diff_minutes[diff_minutes<=2])
n_2
# 370,867,642
n_2/n*100
# 66.19336

diff_minutes_hist <- ifelse(diff_minutes>20, 20, diff_minutes) 

quartz(type="pdf", file="figures/diff_minutes.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/diff_minutes.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(diff_minutes_hist,
     main="Time difference between navigation events", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(0,20),
     ylim=c(0, 400000000),
     breaks=c(0:20),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 400000000, by=50000000)) {
  segments(x0=-5, y0=y, x1=20, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(diff_minutes_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(0,20),
     ylim=c(0, 400000000),
     breaks=c(0:20),
     xaxt="n",
     yaxt="n"
)

# plot median
segments(x0=0, y0=0, x1=0, y1=400000000, lty=2, lwd=2, col=gray_dark)
text(1.65, 380000000, "\u2190 Q1, Median", font=3)
segments(x0=19, y0=0, x1=19, y1=400000000, lty=2, lwd=2, col=gray_dark)
text(18.25, 380000000, "Q3 \u2192", font=3)
# filter
#abline(v=1, lty=2, lwd=2, col=gray_darker) 
# labels
#text(1.8, 122000, "Excluded", font=3)
#text(10.5, 50000, "Selected", font=3)
# axes
axis(1, at=seq(0, 20, 5), labels=c(seq(0, 15, 5), "\u2265 20"))
axis(2, at=seq(0, 400000000, by=50000000), labels=c("0", "50m", "100m", "150m", "200m", "250m", "300m", "350m", "400m"), las=3)
title(xlab="Time difference (minutes)", font.lab=3)
title(ylab="Number of succeeding events", font.lab=3)

dev.off() 


diff_minutes_hist <- diff_minutes[diff_minutes>0 & diff_minutes<20]

quartz(type="pdf", file="figures/diff_minutes_1_19.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/diff_minutes_1_19.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(diff_minutes_hist,
     main="Time difference between navigation events", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,19),
     ylim=c(0, 50000000),
     breaks=c(1:19),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 50000000, by=10000000)) {
  segments(x0=-5, y0=y, x1=19, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(diff_minutes_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,19),
     ylim=c(0, 50000000),
     breaks=c(1:19),
     xaxt="n",
     yaxt="n"
)
# axes
axis(1, at=seq(1, 24), labels=c(seq(1, 24)))
axis(2, at=seq(0, 50000000, by=10000000), labels=c("0", "10m", "20m", "30m", "40m", "50m"), las=3)
title(xlab="Time difference (minutes)", font.lab=3)
title(ylab="Number of succeeding events", font.lab=3)

dev.off() 

################################################################################

# read event count per user
event_count <- fread("data/EventCount.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
event_count <- event_count$V1
n <- length(event_count)
n
# 187,142,541

summary(event_count)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#    1       1       1       4       1 1582409 

quantile(event_count, seq(0.75, 1.0, 0.05))
# 75%     80%     85%     90%     95%    100% 
#   1       1       2       3       7 1582409

n_1 <- length(event_count[event_count==1])
n_1
# 149,881,185
n_1/n*100
# 80.08932

event_count_hist <- ifelse(event_count>8, 8, event_count) 

quartz(type="pdf", file="figures/event_count.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/diff_minutes.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(event_count_hist,
     main="Event count per user identifier", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 200000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 200000000, by=50000000)) {
  segments(x0=-5, y0=y, x1=8, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(event_count_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 200000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)

# plot median
segments(x0=1, y0=0, x1=1, y1=200000000, lty=2, lwd=2, col=gray_dark)
text(1.7, 180000000, "\u2190 Q1, Median, Q3", font=3)
segments(x0=7, y0=0, x1=7, y1=200000000, lty=2, lwd=2, col=gray_dark)
text(6.4, 180000000, "95% quantile \u2192", font=3)
# axes
axis(1, at=seq(1, 8), labels=c(seq(1, 7), "\u2265 8"))
axis(2, at=seq(0, 200000000, by=50000000), labels=c("0", "50m", "100m", "150m", "200m"), las=3)
title(xlab="Event count", font.lab=3)
title(ylab="Number of user identifiers", font.lab=3)

dev.off() 


event_count_hist <- event_count[event_count>1 & event_count<8]

quartz(type="pdf", file="figures/event_count_2_7.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/diff_minutes.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(event_count_hist,
     main="Event count per user identifier", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(2,7),
     ylim=c(0, 20000000),
     breaks=c(2:7),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 20000000, by=5000000)) {
  segments(x0=-5, y0=y, x1=7, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(event_count_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(2,7),
     ylim=c(0, 20000000),
     breaks=c(2:7),
     xaxt="n",
     yaxt="n"
)
# axes
axis(1, at=seq(2, 7), labels=seq(2, 7))
axis(2, at=seq(0, 20000000, by=5000000), labels=c("0", "5m", "10m", "15m", "20m"), las=3)
title(xlab="Event count", font.lab=3)
title(ylab="Number of user identifiers", font.lab=3)

dev.off()

################################################################################

# length of extracted navigation sequences
navigation_sequences_length <- fread("data/NavigationSequencesLength.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_length <- navigation_sequences_length$V1
n <- length(navigation_sequences_length)
n
# 104,103,066

summary(navigation_sequences_length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 2.0      2.0      2.0      4.6      4.0 928826.0 

quantile(navigation_sequences_length, seq(0.75, 1.0, 0.05))
# 75%    80%    85%    90%    95%   100% 
#   4      5      6      7     11 928826 

n_2 <- length(navigation_sequences_length[navigation_sequences_length==2])
n_2
# 54,615,858
n_2/n*100
# 52.46326

navigation_sequences_length_hist <- ifelse(navigation_sequences_length>8, 8, navigation_sequences_length) 

quartz(type="pdf", file="figures/navigation_sequences_length.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/navigation_sequences_length.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(navigation_sequences_length_hist,
     main="Length of navigation sequences", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 75000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 75000000, by=25000000)) {
  segments(x0=-5, y0=y, x1=8, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(navigation_sequences_length_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 100000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)

# axes
axis(1, at=seq(1, 8), labels=c(seq(1, 7), "\u2265 8"))
axis(2, at=seq(0, 75000000, by=25000000), labels=c("0", "25m", "50m", "75m"), las=3)
title(xlab="Length of navigation sequence", font.lab=3)
title(ylab="Count", font.lab=3)

dev.off() 


################################################################################

# length of extracted navigation sequences containing search events
navigation_sequences_search_length <- fread("data/NavigationSequencesSearchLength.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_search_length <- navigation_sequences_search_length$V1
n <- length(navigation_sequences_search_length)
n
# 15,480,434

summary(navigation_sequences_search_length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 2.00     2.00     3.00     5.37     6.00 71330.00

quantile(navigation_sequences_search_length, seq(0.75, 1.0, 0.05))
# 75%   80%   85%   90%   95%  100% 
#   6     7     8    10    13 71330

n_2 <- length(navigation_sequences_search_length[navigation_sequences_search_length==2])
n_2
# 4,671,742
n_2/n*100
# 30.17837

navigation_sequences_search_length_hist <- ifelse(navigation_sequences_search_length>8, 8, navigation_sequences_search_length) 

quartz(type="pdf", file="figures/navigation_sequences_search_length.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/navigation_sequences_search_length.pdf", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(navigation_sequences_search_length_hist,
     main="Length of navigation sequences containing search", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 5000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 5000000, by=1000000)) {
  segments(x0=-5, y0=y, x1=8, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(navigation_sequences_search_length_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 5000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)

# axes
axis(1, at=seq(1, 8), labels=c(seq(1, 7), "\u2265 8"))
axis(2, at=seq(0, 5000000, by=1000000), labels=c("0", "1m", "2m", "3m", "4m", "5m"), las=3)
title(xlab="Length of navigation sequence", font.lab=3)
title(ylab="Count", font.lab=3)

dev.off() 

################################################################################

# length of extracted navigation sequences starting in threads
navigation_sequences_thread_length <- fread("data/NavigationSequencesThreadLength.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_thread_length <- navigation_sequences_thread_length$V1
n <- length(navigation_sequences_thread_length)
n
# 48,403,370

summary(navigation_sequences_thread_length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 2.00     2.00     2.00     3.16     3.00 49815.00 

quantile(navigation_sequences_thread_length, seq(0.75, 1.0, 0.05))
# 75%   80%   85%   90%   95%  100% 
#   3     3     4     5     7 49815 

n_2 <- length(navigation_sequences_thread_length[navigation_sequences_thread_length==2])
n_2
# 32,993,399
n_2/n*100
# 68.16343

navigation_sequences_thread_length_hist <- ifelse(navigation_sequences_thread_length>8, 8, navigation_sequences_thread_length) 

quartz(type="pdf", file="figures/navigation_sequences_thread_length.pdf", width=12, height=10) # prevents unicode issues in pdf
#pdf("figures/navigation_sequences_thread_length", width=12, height=10)
par(
  bg="white",
  # mar = c(3, 1.8, 3, 1.5)+0.1, # subplot margins (bottom, left, top, right)
  # omi = c(0.0, 0.0, 0.0, 0.0),  # outer margins in inches (bottom, left, top, right)
  # mfrow = c(2, 1),
  # pin = (width, height)
  # mfcol # draw in columns
  # increase font size
  cex=1.3,
  cex.main=1.3,
  cex.sub=1,
  cex.lab=1,
  cex.axis=1
)

# histogram
hist(navigation_sequences_thread_length_hist,
     main="Length of navigation sequences starting in a SO threads", 
     freq=TRUE,
     xlab="",
     ylab="",
     border="white",
     col="white",
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 35000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)
for (y in seq(0, 35000000, by=5000000)) {
  segments(x0=-5, y0=y, x1=8, y1=y, lty=1, lwd=1, col=gray_lighter)
}
hist(navigation_sequences_thread_length_hist,
     add=TRUE,
     main="", 
     freq=TRUE,
     xlab="",
     ylab="",
     border=gray_darker,
     col=gray_lighter,
     #labels=c(rep("", 10), "Selected"),
     xlim=c(1,8),
     ylim=c(0, 5000000),
     breaks=c(1:8),
     xaxt="n",
     yaxt="n"
)

# axes
axis(1, at=seq(1, 8), labels=c(seq(1, 7), "\u2265 8"))
axis(2, at=seq(0, 35000000, by=5000000), labels=c("0", "5m", "10m", "15m", "20m", "25m", "30m", "35m"), las=3)
title(xlab="Length of navigation sequence (#Events)", font.lab=3)
title(ylab="Count", font.lab=3)

dev.off() 

################################################################################

# length of extracted navigation sequences (new threshold, possible bot traffic and non-linear sequences excluded)
navigation_sequences_length <- fread("data/NavigationSequencesLengthFiltered1.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_length <- navigation_sequences_length$V1
n <- length(navigation_sequences_length)
n
# 18,269,793

summary(navigation_sequences_length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 2.000    2.000    2.000    2.582    3.000 4215.00

quantile(navigation_sequences_length, seq(0.75, 1.0, 0.05))
# 75%  80%  85%  90%  95% 100% 
#   3    3    3    4    5 4215

quantile(navigation_sequences_length, seq(0.95, 1.0, 0.01))
# 95%  96%  97%  98%  99% 100% 
#   5    5    6    6    8 4215

n_2 <- length(navigation_sequences_length[navigation_sequences_length==2])
n_2
# 12,766,640
n_2/n*100
# 69.87841

# outlier (k=1.5)
k <- 1.5
outlier_thresholds(navigation_sequences_length, k)
# lower upper
# 0.5   4.5
outlier_count(navigation_sequences_length, k)
# 1,116,979
outlier_percent(navigation_sequences_length, k)
# 6.113802

# far outlier (k=3)
k <- 3
outlier_thresholds(navigation_sequences_length, k)
# lower upper
# -1     6
outlier_count(navigation_sequences_length, k)
# 332,784
outlier_percent(navigation_sequences_length, k)
# 1.821498

navigation_sequences_length_table <- table(navigation_sequences_length)
plot_data(navigation_sequences_length_table, 2, 16)
plot_data(navigation_sequences_length_table, 6, 16)

m <- get_slope(navigation_sequences_length_table, 2, 16)
m
#            slope slope_diff
# (2,3)   -9591761          0
# (3,4)   -1963584   -7628177
# (4,5)    -682258   -1281326
# (5,6)    -273879    -408379
# (6,7)    -123939    -149940
# (7,8)     -59022     -64917
# (8,9)     -26503     -32519
# (9,10)     -9680     -16823
# (10,11)   -21768      12088
# (11,12)    -5299     -16469
# (12,13)    -3081      -2218
# (13,14)    -1930      -1151
# (14,15)    -1167       -763
# (15,16)     -723       -444

################################################################################

# length of extracted navigation sequences (new threshold, possible bot traffic, page refreshes, and non-linear sequences excluded)
navigation_sequences_length <- fread("data/NavigationSequencesLengthFiltered2.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_length <- navigation_sequences_length$V1
n <- length(navigation_sequences_length)
n
# 16,164,506

summary(navigation_sequences_length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 2.000    2.000    2.000    2.609    3.000 1593.000

quantile(navigation_sequences_length, seq(0.75, 1.0, 0.05))
# 75%  80%  85%  90%  95% 100% 
#   3    3    3    4    5 1593 

quantile(navigation_sequences_length, seq(0.95, 1.0, 0.01))
# 95%  96%  97%  98%  99% 100% 
#   5    5    6    6    8 1593

n_2 <- length(navigation_sequences_length[navigation_sequences_length==2])
n_2
# 11,055,707
n_2/n*100
# 68.39496

navigation_sequences_length_table <- table(navigation_sequences_length)
plot_data(navigation_sequences_length_table, 2, 16)
plot_data(navigation_sequences_length_table, 6, 16)

m <- get_slope(navigation_sequences_length_table, 2, 16)
m
# (2,3)   -8148785          0
# (3,4)   -1759911   -6388874
# (4,5)    -638316   -1121595
# (5,6)    -262006    -376310
# (6,7)    -120919    -141087
# (7,8)     -57843     -63076
# (8,9)     -29837     -28006
# (9,10)    -15614     -14223
# (10,11)    -8703      -6911
# (11,12)    -5165      -3538
# (12,13)    -3005      -2160
# (13,14)    -1865      -1140
# (14,15)    -1113       -752
# (15,16)     -701       -412

################################################################################

# length of navigation sequences containing search events and ending in a thread
navigation_sequences_length <- fread("data/NavigationSequencesSearchThreadLength.csv", header=FALSE, sep=",", quote="\"", strip.white=TRUE, showProgress=TRUE, encoding="UTF-8", na.strings=c("", "null"), stringsAsFactors=FALSE)
navigation_sequences_length <- navigation_sequences_length$V1
n <- length(navigation_sequences_length)
n
# 3,125,427

summary(navigation_sequences_length)
#  Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 2.000   2.000   2.000   2.593   3.000  52.000 

quantile(navigation_sequences_length, seq(0.75, 1.0, 0.05))
# 75%  80%  85%  90%  95% 100% 
#   3    3    3    4    5   52 

n_2 <- length(navigation_sequences_length[navigation_sequences_length==2])
n_2
# 2,083,146
n_2/n*100
# 66.65156

# plot distribution
navigation_sequences_length_table <- table(navigation_sequences_length)
plot_data(navigation_sequences_length_table, 2, 16)
#plot_data(navigation_sequences_length_table, 6, 16)

m <- get_slope(navigation_sequences_length_table, 2, 16)
m
#            slope slope_diff
# (2,3)   -1472866          0
# (3,4)    -368092   -1104774
# (4,5)    -142792    -225300
# (5,6)     -53676     -89116
# (6,7)     -24467     -29209
# (7,8)     -10633     -13834
# (8,9)      -4979      -5654
# (9,10)     -2708      -2271
# (10,11)    -1238      -1470
# (11,12)     -769       -469
# (12,13)     -333       -436
# (13,14)     -236        -97
# (14,15)     -139        -97
# (15,16)      -87        -52
