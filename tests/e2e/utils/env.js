this.url = function getURL() {
    var env = process.env.PROFILE;
    console.log("------------"+ env);
    return env
    //switch(env) {
    //    case "prod":
    //        break;
    //}
};