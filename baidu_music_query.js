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


var music_search = casper.cli.get(0);
var music_id = casper.cli.get(1) ;

var start = casper.cli.get("page") || 1;
start = 20*(start-1);

var url = 
"http://music.baidu.com/search?key=" + music_search + "&start=" + start;

if(music_id) fs.write(music_id, '', 'w');

casper.start(url);

casper.wait(1000, function(){
            var song_x = '//div[@class="search-song-list song-list song-list-hook"]//li[@class="bb-dotimg clearfix song-item-hook  "]';
            var song_info = this.getElementsAttribute(x(song_x), 'data-songitem');
            for(var i in song_info){
                var info = JSON.parse(song_info[i]);
                var res = info.songItem;
                var sid = parseInt(res.sid);
                if(! sid) continue;
                var s_info = [ format_song_string(res.author), 
                format_song_string(res.sname), sid ].join(" ");

                if(music_id){
                    fs.write(music_id,s_info+"\n", 'a'); 
                }else{
                    console.log(s_info);
                }
            }
        });
casper.run();

function format_song_string(s){
        return s.replace(/\s+/g, '-').replace(/<[^>]+>/g, '').
            replace(/[,\\\/\$]/g, ''); 
}
