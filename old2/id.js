var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');

var casper = require('casper').create({
//    logLevel: 'debug', verbose: true, 
    pageSettings: {
        loadImages:  false,        
    loadPlugins: false  // not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);

casper.on('open', function (location) {
        console.log(location + ' loaded');
});

casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');

casper.start('http://music.baidu.com');

var music_search = casper.cli.get(0);
var music_id = casper.cli.get(1) ;

var search_list = read_music_file(music_search);

if(music_id) fs.write(music_id, '', 'w');

casper.eachThen(search_list, function(item){
        var title = item.data[0];
        var artist = item.data[1];
        var key = title;
        if(artist) key +=" "+artist;
        //console.log("search song: " + key);

//        this.thenOpen('http://music.baidu.com')
//        .wait(1000, function(){
//            this.fill('form[action="/search"]', { key : key }, true);
//        })

        key=key.replace(/ /g, '+');
        this.thenOpen('http://music.baidu.com/search?key='+key)
        .wait(1000, function(){
            fs.write('a.html', this.getHTML());
            var song_x = artist ? '//a/em[text()="' + artist + '"]//ancestor::div[@class="song-item clearfix"]' : '';
            song_x +="//span[@class='song-title']//a[@title='" + title + "']";
            var song_xp = x(song_x);
            var artist_xp = x('//span[@class="author_list"]');
            if (this.exists(song_xp)) {
                var id = this.getElementAttribute(song_xp,'href');
                var song_id = id.replace(/\/song\/(.*?)\/.*/, "$1").replace(/\/song\/(.*?)$/, "$1");
                var artist = this.getElementAttribute(artist_xp, 'title');
                //console.log('find song: '+ key + ' id ' + song_id);
                var song_info = [ artist.replace(/\s+/g, '-'), 
                    title.replace(/\s+/g, '-'), song_id].join(" ");
                if(song_id.match(/^\d+/)){
                    if(music_id){
                        fs.write(music_id,song_info+"\n", 'a'); 
                    }else{
                        console.log(song_info);
                    }
                }
            } 
        });
    });
    
casper.run();

function read_music_file(f) {
    var music_data = fs.read(f).match(/[^\r\n]+/g);
    var res = new Array();
    for(var m in music_data){
        var info = music_data[m].split(/\s+/g);
        if(!info) continue;
        res.push(info);
    }
    return res;
}
