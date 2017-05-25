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

var cookie_file = casper.cli.get(0);
var data = fs.read(cookie_file);
phantom.cookies = JSON.parse(data);

var id_file = casper.cli.get(1);
var music_list = read_music_file(id_file);

casper.start('http://music.baidu.com');
casper.each(music_list, function(self, item){
        var song_id = item[2];
        if(!song_id) return;
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
