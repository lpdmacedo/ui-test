require("../utils/env.js")

module.exports = {
    /**
     * Set up for tests
     * @param browser
     */
    before: function(browser) {
        var env = process.env.PROFILE;
        switch(env) {
            case 'local': url = browser.globals.local.url.mla
                break;
            default: url = browser.globals.prod.url.mla
        }
    },

    /**
     * Method executed after tests
     * @param browser
     */
    after: function(browser) {
        browser.end()
    },

    /**
     * Init a web browser without cookies
     * @param browser
     */
    beforeEach: function(browser) {
        browser.deleteCookies(function() {})
    },

    /**
     * Test specification
     */
    '@tags': ['mla'],
    'Dummy Test': function(browser) {
        console.log("[Dummy Test][URL: " + url + "]");
        browser.page.MyPageObject()
            .open(url)
            .verifyLink();
    }
};
