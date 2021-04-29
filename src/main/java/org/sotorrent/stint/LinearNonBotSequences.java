package org.sotorrent.stint;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name="LinearNonBotSequences")
public class LinearNonBotSequences {

    private int rootEventId;

    public LinearNonBotSequences() {}

    public LinearNonBotSequences(int rootEventId) {
        this.rootEventId = rootEventId;
    }

    @Id
    @Column(name = "RootEventId")
    public Integer getRootEventId() {
        return rootEventId;
    }

    public void setRootEventId(Integer rootEventId) {
        this.rootEventId = rootEventId;
    }
}
