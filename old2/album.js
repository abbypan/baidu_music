var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');

function decode(s) {
    return unescape(s.replace(/\\(u[0-9a-fA-F]{4})/gm, '%$1'));
}

var casper = require('casper').create({
    //logLevel: 'debug', verbose: true, 
    pageSettings: {
        loadImages:  false,        
    loadPlugins: false  // not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);
casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');


var album_url = casper.cli.get(0);
var music_id = casper.cli.get(1) ;

casper.start(album_url);

var album_info = new Array();
casper.then(function(){
    var body_html = this.getHTML(x('//div[@class="body "]'));
    var ul = body_html.match(/songItem.*?({.+?})/g);

    for(var i in ul){
        var nul = ul[i].replace(/&quot;/g,"'").replace(/^/, "'");
        var sid = nul.match(/'sid':'(.+?)'/);
        var author = nul.match(/'author':'(.+?)'/);
        var sname = nul.match(/'sname':'(.+?)'/);

        var song_info = [ 
    decode(author[1]).replace(/\s+/g,'-'), 
    decode(sname[1]).replace(/\s+/g,'-'), 
    decode(sid[1]) ].join(" ");

    album_info.push(song_info);
    }

var s = album_info.join("\n");
if(music_id){
    fs.write(music_id, s, 'w');
}else{
    console.log(s);
}
});

casper.run();

