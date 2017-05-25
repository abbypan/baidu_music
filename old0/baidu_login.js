var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');

var casper = require('casper').create({
    //{logLevel: 'debug', verbose: true}, 
    pageSettings: {
        loadImages:  false,        
    loadPlugins: false  // not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);
casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');

casper.start('http://music.baidu.com');

var usr = casper.cli.get(0);
var passwd = casper.cli.get(1);
var cookie = casper.cli.get(2);

casper.then(function(){
    if( utils.isUndefined(usr) || utils.isUndefined(passwd) ) return;

    console.log("begin login : "+usr);
    var login_url = 'https://passport.baidu.com/v2/?login&amp;tpl=mn&amp;u=http%3A%2F%2Fwww.baidu.com%2F';
    this.open(login_url);
        this.wait(1000, function(){
        this.click('#pass-user-login')
        });
        this.thenEvaluate(function(usr,passwd) {
        document.querySelector('#TANGRAM__3__userName').setAttribute('value', usr);
        document.querySelector('#TANGRAM__3__password').setAttribute('value', passwd);
    }, { 'usr' : usr, 'passwd' : passwd })
        .thenClick('#TANGRAM__3__submit')
    .wait(1000, function () {
        console.log("finish login : "+usr);
    });
});

casper.then(function () {
    if( utils.isUndefined(usr) ||  utils.isUndefined(passwd) ||  utils.isUndefined(cookie) ) return;
    console.log("write cookie file : " + cookie);
    var cookie_str = JSON.stringify(phantom.cookies);
    fs.write(cookie,cookie_str, 'w');
});

casper.run();
