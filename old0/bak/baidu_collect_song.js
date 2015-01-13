//var casper = require('casper').create({logLevel: 'debug', verbose: true});
var casper = require('casper').create(
    {
    pageSettings: {
        loadImages:  false,        // do not load images
        loadPlugins: false         // do not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);
casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');
var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');

var cookie_file = casper.cli.get(0);
var data = fs.read(cookie_file);
phantom.cookies = JSON.parse(data);

var title = casper.cli.get(1);
var artist = casper.cli.get(2);

casper.start();

var song_id = 0;
search_song( title, artist );
collect_song();
casper.run();

function collect_song() {
    casper.then(function(){
        if(song_id==0) return;
        var collect_url = 'http://music.baidu.com/song/' + song_id;

        this.thenOpen(collect_url, function(){
            console.log("visit url : " + collect_url);

            var collect_x  = x('//span[text()="收藏"]/parent::span/parent::a');
            if (this.exists(collect_x)) {
                console.log("click collect button : "+song_id);
                this.click(collect_x);
            }

            this.wait(1000, function() {
                var artist = this.getElementAttribute('span[class="author_list"]', 'title')
                var title = this.fetchText('span[class="name"]');
                status = this.fetchText('div[class="song-page-share clearfix"] span span');
                status = status.replace('分享','');
                console.log("song "+ artist + "《 " + title +" 》 : " + status+"\n");
            });
        });
    });
}

function search_song (title, artist){
    song_id = 0;

    var key = title;
    if(artist) key +=" "+artist;
    console.log('search song : ' + key);

    var music_url = 'http://music.baidu.com';
    casper.thenOpen(music_url);
    casper.wait(1000, function(){
        this.fill('form[action="/search"]', { key : key }, true);
    });

    casper.wait(1000, function(){
        //fs.write('baidu_login.html', this.getHTML('div[monkey="song-list"]'), 'w');
    });

    casper.then(function(){
        var song_x = artist ? '//a/em[text()="' + artist + '"]//ancestor::div[@class="song-item clearfix"]' : '';
        song_x +="//span[@class='song-title']//a[@title='" + title + "']";
        var collect_x = x(song_x);
        if (this.exists(collect_x)) {
            var id = this.getElementAttribute(collect_x,'href');
            song_id = id.replace(/#.*/, '').replace(/^.*\//, '');
        }
    });

    casper.then(function(){
        console.log('find song id ' + song_id);
    });
}
