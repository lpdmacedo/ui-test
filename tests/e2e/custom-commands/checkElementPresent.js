var util = require('util');
var jrequire = require('./_jrequire.js');
var WaitForElement = jrequire('_waitForElement.js');

//TEST DOES NOT FAIL IF THE ELEMENT IS NOT PRESENT. RESULT COULD BE true (IF ELEMENT IS PRESENT) OR false (if element is not present).
function CheckElementPresent() {
    WaitForElement.call(this);
    this.expectedValue = 'found';
}

util.inherits(CheckElementPresent, WaitForElement);

CheckElementPresent.prototype.elementFound = function(result, now) {
    var defaultMsg = 'Element <%s> was present after %d milliseconds.';
    return this.pass(result, defaultMsg, now - this.startTimer);
};

CheckElementPresent.prototype.elementNotFound = function(result, now) {
    if (now - this.startTimer < this.ms) {
        // element wasn't found, schedule another check
        this.reschedule();
        return this;
    }
    var defaultMsg = 'Element <%s> was not present after %d milliseconds.';
    return this.pass({value:false}, defaultMsg, now - this.startTimer);
};

module.exports = CheckElementPresent;
