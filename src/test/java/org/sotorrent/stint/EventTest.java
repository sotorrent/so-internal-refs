package org.sotorrent.stint;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class EventTest {
    @Test
    void testQueryExtraction() {
        Event event;

        event = new Event();
        event.setUrl("/questions/1082130/how-do-i-remove-a-mysql-database?s=1|110.8094");
        event.extractQuery();
        assertEquals("s=1|110.8094", event.getQuery());

        event = new Event();
        event.setUrl("/questions/20060915/javascript-how-do-you-set-the-value-of-a-button-with-an-element-from-an-array?answertab=active");
        event.extractQuery();
        assertEquals("answertab=active", event.getQuery());

        event = new Event();
        event.setUrl("/questions/38997881/selenium-tests-dont-work-in-ie11?noredirect=1&lq=1");
        event.extractQuery();
        assertEquals("noredirect=1&lq=1", event.getQuery());

        event = new Event();
        event.setUrl("/search?q=%D0%BF%D0%B5%D1%80%D0%B5%D0%B2%D0%BE%D0%B4+%D0%BD%D0%B0+%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9");
        event.extractQuery();
        assertEquals("q=%D0%BF%D0%B5%D1%80%D0%B5%D0%B2%D0%BE%D0%B4+%D0%BD%D0%B0+%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9", event.getQuery());

        event = new Event();
        event.setUrl("/search?q=frequency+mask+trigger");
        event.extractQuery();
        assertEquals("q=frequency+mask+trigger", event.getQuery());

        event = new Event();
        event.setUrl("/questions/3625659/java-io-ioexception-server-returns-http-response-code-505?answertab=active#23tab-top");
        event.extractQuery();
        assertEquals("answertab=active", event.getQuery());

        event = new Event();
        event.setUrl("/questions/tagged/ide?pageSize=-1#22%20OR%203%2b877-877-1=0%2b0%2b0%2b1%20--%20&sort=newest");
        event.extractQuery();
        assertEquals("pageSize=-1", event.getQuery());

        event = new Event();
        event.setUrl("/search?q=[google-app-engine]+video+streaming");
        event.extractQuery();
        assertEquals("q=[google-app-engine]+video+streaming", event.getQuery());
    }

    @Test
    void testFragmentIdentifierExtraction() {
        Event event;

        event = new Event();
        event.setUrl("/questions/3625659/java-io-ioexception-server-returns-http-response-code-505?answertab=active#23tab-top");
        event.extractFragmentIdentifier();
        assertEquals("23tab-top", event.getFragmentIdentifier());

        event = new Event();
        event.setUrl("/questions/30038675/plupload-2-doesnt-trigger-camera-in-html5-runtime-on-ipad?answertab=active&from=en&to=zh-CHS&tfr=web&domainType=sogou#22");
        event.extractFragmentIdentifier();
        assertEquals("22", event.getFragmentIdentifier());

        // the following test cases test how well the extraction performs for potentially malformed URLs

        event = new Event();
        event.setUrl("/questions/tagged/ide?pageSize=-1#22%20OR%203%2b877-877-1=0%2b0%2b0%2b1%20--%20&sort=newest");
        event.extractFragmentIdentifier();
        assertEquals("22%20OR%203%2b877-877-1=0%2b0%2b0%2b1%20--%20&sort=newest", event.getFragmentIdentifier());

        event = new Event();
        event.setUrl("/questions/tagged/sql?page=5&pageSize=15&sort=%f0''%f0#22#22");
        event.extractFragmentIdentifier();
        assertEquals("22#22", event.getFragmentIdentifier());

        event = new Event();
        event.setUrl("/users?filter=week&page=3&tab=reputation'#22()%26%25<acx><ScRiPt%20>ph7t(9084)</ScRiPt>");
        event.extractFragmentIdentifier();
        assertEquals("22()%26%25<acx><ScRiPt%20>ph7t(9084)</ScRiPt>", event.getFragmentIdentifier());

        event = new Event();
        event.setUrl("/questions/tagged/ide?pageSize=15&sort=if(now()=sysdate()%2csleep(6)%2c0)/*'XOR(if(now()=sysdate()%2csleep(6)%2c0))OR'#22XOR(if(now()=sysdate()%2csleep(6)%2c0))OR#22*/");
        event.extractFragmentIdentifier();
        assertEquals("22XOR(if(now()=sysdate()%2csleep(6)%2c0))OR#22*/", event.getFragmentIdentifier());
    }
}
