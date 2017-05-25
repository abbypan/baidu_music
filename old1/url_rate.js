var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');
var clientutils = require('clientutils').create();

var casper = require('casper').create({
    //{logLevel: 'debug', verbose: true}, 
    pageSettings: {
        loadImages:  false,        
    loadPlugins: false  // not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);
casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');

//casper.start('http://music.baidu.com');
casper.start();

var music_id = casper.cli.get(0) ;
var music_url = casper.cli.get(1);

// 音质：0 (最好) ~ 3 (最差)
var music_level =  casper.cli.get("level") || 0;

// 格式：flac/mp3，也可以不指定
var music_format =  casper.cli.get("format");  

search_list = read_music_file(music_id);

if(music_url) fs.write(music_url, '', 'w');

casper.eachThen(read_music_file(music_id), function(item){
    var artist = item.data[0];
    var title = item.data[1];
    var song_id = item.data[2];

    var rate=0;
    if(song_id){
        var url = "http://musicmini.baidu.com/app/link/getLinks.php";
        var param = {
            "songId":song_id,
    "songsId":song_id,
    "songsiId":song_id,
    "songAppend":"",
    "linkType":1,
    "isLogin":1,
    "clientVer":"",
    "isHq":1,
    "isCloud":0,
    "hasMV":1,
    "noFlac":0,
    "rate":0
        };
        var param_str = JSON.stringify(param);
        var param_s = clientutils.encode(param_str) ;
        this.thenOpen(url, {
            method: 'post', 
            data: {
                'param' : param_s
            }
        }, function(){
            var s = this.getHTML('body');
            if(! s.match(/^\[/)) return;
            var song_info = JSON.parse(s);
            if(! song_info) return;
            if(! song_info[0]) return;

            var files = song_info[0]["file_list"];
            var file_cnt = files.length;
            var song_level = music_level;

            if(song_level>=file_cnt) song_level = file_cnt;
            var u = files[song_level];

            if(music_format && ( u["format"] != music_format )){
                song_level++;
                if(song_level>=file_cnt) song_level = file_cnt;
                u = files[song_level];
            }
            var info = {
                id: song_info[0]["song_id"], 
                artist: artist,
                title: title,
                kbps: u["kbps"],
                format: u["format"],
                //url: u["url"].replace(/&.*$/,''),
                album_img: song_info[0]["album_img"]
            };
            var w_str = JSON.stringify(info);

            if(music_url){
                fs.write(music_url, w_str+"\n", 'a'); 
            }else{
                console.log(w_str);
            }

        });
    }
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

function format_song_string(s){
    var x = s.replace(/\s+/g, '-').replace(/<[^>]+>/g, '').
        replace(/[,\\\/\$]/g, '-'); 
    return x || 'unknown';
}
