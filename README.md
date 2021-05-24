# so-internal-refs
Scripts used to import and analyze internal web server logs provided by Stack Overflow under an NDA.

[![logo](doc/stint-logo_small.png "sting logo")](doc/stint-logo.png)

## Execution

To extract navigation sequences from the event log, run:

    java -jar stint-1.1.0-jar-with-dependencies.jar -h hibernate.cfg.xml -d data
    
To further process linear navigation sequences, run:

    java -jar stint-1.1.0-jar-with-dependencies.jar -h hibernate.cfg.xml -d data -l

## Implemented Filtering Strategy

The dataset shared with us by Stack Overflow under an NDA contains all  747,421,780 internal  HTTP(S)  requests processed by  Stack  Overflow's web servers within one year, from December  2017  until  November  2018. "Internal requests"  means that the dataset only contains requests with a  referrer  URL  on `stackoverflow.com`.  If a  user,  for example,  reached a Stack Overflow post by clicking on a Google search result and then triggered a search within Stack Overflow, only the second (internal) search request would be included in the dataset, not the request for the post having a Google referrer. For each HTTP request, the dataset contains an anonymized user identifier that represents logged-in registered users as well as users identified by a  browser cookie or users identified by their IP address. This dataset also assigns certain event types to the requests  (e.g.,  searching,  post visiting,  or question list browsing), depending on their target URL. We preprocess the data as follows:

1. We group all events per user identifier and then order them chronologically.
2. To distinguish between individual sessions,  we group the  747,421,780 web server requests into sequences of requests that are not more than six minutes apart,  following [Sadowski et al.](https://doi.org/10.1145/2786805.2786855)'s approach.
3. We apply an additional filtering step to avoid gaps in the data caused by the focus on internal requests. A user may, for example, follow external links in Stack Overflow posts and then navigate back to Stack Overflow or open multiple posts in parallel browser tabs. For our studies, we focus on a complete linear navigation sequence, that is sequences where the referrer of one request matches the target  URL  of the previous request. 74,613,186 (75.75%) of the above-mentioned sequences were non-linear, i.e. they contained gaps where users visited external (non-Stack Overflow) websites or opened multiple Stack Overflow pages in parallel.
4. We further utilize heuristics based on timestamps and request targets to filter out noise in the form of bot traffic and event sequences merely consisting of page refreshes. After excluding bot traffic, we ended up with 18,269,793 (18.55%) linear non-bot sequences. From those sequences, we further removed page refresh events where users accessed the same URL multiple times in a very short period, which we noticed to happen quite frequently. This yielded 16,164,506 sequences (88.48% of the linear non-bot sequences).

Applying the above data preprocessing steps yielded a dataset of *complete linear navigation sequences*. All those steps were developed in an iterative process, involving qualitative analysis of samples of sequences to detect problematic instances (non-linear sequences, bot traffic, page refreshes, etc.). The code implementing this data pipeline is available in this repository.

## Publications

**Characterizing Search Activities on Stack Overflow.**<br/>
Jiakun Liu, Sebastian Baltes, Christoph Treude, David Lo, Yun Zhang, Xin Xia.<br/>
*Proceedings of the 29th ACM Joint European Software Engineering Conference and Symposium on the Foundations of Software Engineering (ESEC/FSE 2021) (to appear).*

**Automated Query Reformulation for Efficient Search Based on Query Logs from Stack Overflow.**<br/>
Kaibo Cao, Chunyang Chen, Sebastian Baltes, Christoph Treude, Xiang Chen.<br/>
*Proceedings of the 43rd International Conference on Software Engineering (ICSE 2021) (to appear).*
