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


var album_url = casper.cli.get(0);
var music_id = casper.cli.get(1) ;

casper.start(album_url);

var album_info = new Array();
casper.then(function(){
        var album_xp = x('//*[@class="album-name"]');
           
            var album_name = this.exists(album_xp) ? this.getHTML('.album-name') : this.getHTML('h2.name');
            console.log('album: ' + album_name);
        var ul = this.getHTML('div.body').
            match(/{ 'songItem': ({.+?}) }/g)
            ;
            for(var i in ul){
                var li = ul[i].match(/'sid': '(.+?)', 'sname': '(.+?)', 'author': '(.+?)'/);
                var song_info = [ li[3].replace(/\s/g,''), 
                    li[2].replace(/\s/g,''), 
                    li[1] ].join(" ");
                album_info.push(song_info);
            }

            var dst_file = music_id || album_name +'.txt';
            fs.write(dst_file, album_info.join("\n"), 'w');
    });
    

casper.run();

