package org.sotorrent.stint;

import javax.persistence.*;
import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Entity
@Table(name="Event")
public class Event {

    private int id;
    private Integer rootEventId;
    private String userIdentifier;
    private Date creationDate;
    private Long diffSeconds;
    private String eventSource;
    private String eventTarget;
    private String referrer;
    private String url;
    private String query;
    private String fragmentIdentifier;
    private String normalizedReferrer;
    private String normalizedUrl;
    private boolean botTraffic;
    private boolean gapInSequence;
    private boolean pageRefresh;

    private Pattern queryPattern = Pattern.compile("\\?[^#]*");
    private Pattern fragmentIdentifierPattern = Pattern.compile("#.*");

    public Event() {}

    public Event(int id, Integer rootEventId, String userIdentifier, Date creationDate, Long diffSeconds,
                 String eventSource, String eventTarget, String referrer, String url,
                 String normalizedReferrer, String normalizedUrl,
                 boolean botTraffic, boolean gapInSequence, boolean pageRefresh) {
        this.id = id;
        this.rootEventId = rootEventId;
        this.userIdentifier = userIdentifier;
        this.creationDate = creationDate;
        this.diffSeconds = diffSeconds;
        this.eventSource = eventSource;
        this.eventTarget = eventTarget;
        this.referrer = referrer;
        this.url = url;
        this.normalizedReferrer = normalizedReferrer;
        this.normalizedUrl = normalizedUrl;
        this.botTraffic = botTraffic;
        this.gapInSequence = gapInSequence;
        this.pageRefresh = pageRefresh;
    }

    @Id
    @Column(name = "Id")
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    @Basic
    @Column(name = "RootEventId")
    public Integer getRootEventId() {
        return rootEventId;
    }

    public void setRootEventId(Integer rootEventId) {
        this.rootEventId = rootEventId;
    }

    @Basic
    @Column(name = "UserIdentifier")
    public String getUserIdentifier() {
        return userIdentifier;
    }

    public void setUserIdentifier(String userIdentifier) {
        this.userIdentifier = userIdentifier;
    }

    @Basic
    @Column(name = "CreationDate")
    public Date getCreationDate() {
        return creationDate;
    }

    public void setCreationDate(Date creationDate) {
        this.creationDate = creationDate;
    }

    @Basic
    @Column(name = "DiffSeconds")
    public Long getDiffSeconds() {
        return diffSeconds;
    }

    public void setDiffSeconds(Long diffSeconds) {
        this.diffSeconds = diffSeconds;
    }

    @Transient
    void setDiffSeconds(Event previousEvent) {
        setDiffSeconds((creationDate.getTime()-previousEvent.getCreationDate().getTime())/1000);
    }

    @Basic
    @Column(name = "EventSource")
    public String getEventSource() {
        return eventSource;
    }

    public void setEventSource(String eventSource) {
        this.eventSource = eventSource;
    }

    @Basic
    @Column(name = "EventTarget")
    public String getEventTarget() {
        return eventTarget;
    }

    public void setEventTarget(String eventTarget) {
        this.eventTarget = eventTarget;
    }

    @Basic
    @Column(name = "Referrer")
    public String getReferrer() {
        return referrer;
    }

    public void setReferrer(String referrer) {
        this.referrer = referrer;
    }

    @Basic
    @Column(name = "Url")
    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    @Basic
    @Column(name = "Query")
    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    @Basic
    @Column(name = "FragmentIdentifier")
    public String getFragmentIdentifier() {
        return fragmentIdentifier;
    }

    @Transient
    public void extractQuery() {
        Matcher queryMatcher = queryPattern.matcher(url);
        if (queryMatcher.find()) {
            setQuery(queryMatcher.group(0).substring(1));
        }
    }

    @Transient
    public void extractFragmentIdentifier() {
        Matcher fragmentIdentifierMather = fragmentIdentifierPattern.matcher(url);
        if (fragmentIdentifierMather.find()) {
            setFragmentIdentifier(fragmentIdentifierMather.group(0).substring(1));
        }
    }

    public void setFragmentIdentifier(String fragmentIdentifier) {
        this.fragmentIdentifier = fragmentIdentifier;
    }
    @Basic
    @Column(name = "NormalizedReferrer")
    public String getNormalizedReferrer() {
        return normalizedReferrer;
    }

    public void setNormalizedReferrer(String normalizedReferrer) {
        this.normalizedReferrer = normalizedReferrer;
    }

    @Basic
    @Column(name = "NormalizedUrl")
    public String getNormalizedUrl() {
        return normalizedUrl;
    }

    public void setNormalizedUrl(String normalizedUrl) {
        this.normalizedUrl = normalizedUrl;
    }

    @Basic
    @Column(name = "BotTraffic")
    public boolean getBotTraffic() {
        return botTraffic;
    }

    public void setBotTraffic(boolean botTraffic) {
        this.botTraffic = botTraffic;
    }

    @Basic
    @Column(name = "GapInSequence")
    public boolean getGapInSequence() {
        return gapInSequence;
    }

    public void setGapInSequence(boolean gapInSequence) {
        this.gapInSequence = gapInSequence;
    }

    @Basic
    @Column(name = "PageRefresh")
    public boolean getPageRefresh() {
        return pageRefresh;
    }

    public void setPageRefresh(boolean pageRefresh) {
        this.pageRefresh = pageRefresh;
    }
}
