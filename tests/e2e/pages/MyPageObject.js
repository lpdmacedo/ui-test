module.exports = function (browser) {

    /**
     * Define locator to interact with web element
     * @type {RegExp}
     */
    var regexItemId = new RegExp("([A-Z]{3})-([0-9]+)"),
        selectors = {
            "LINK_SELL": "#sellBtn > a"
        };

    /**
     * Used to display url in the web browser
     * @param url
     * @returns {*}
     */
    this.open = function open(url) {
        browser.url(url);
        return browser.page.MyPageObject();
    };

    /**
     * Simple function to validate link sell displayed in vip MELI
     */
    this.verifyLink = function() {
        browser.assert.containsText(selectors.LINK_SELL, "Vender")
    };
};
