var x = require('casper').selectXPath;
var fs = require('fs');
var system = require('system');
var utils = require('utils');

var casper = require('casper').create({
    //logLevel: 'debug', verbose: true, 
    pageSettings: {
        loadImages:  false,        
        loadPlugins: false  // not load NPAPI plugins (Flash, Silverlight, ...)
    }
}
);
casper.userAgent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:18.0) Gecko/20130119 Firefox/18.0');

var callback_info = {
    xspf : music_xspf_cb, 
    online : null, 
    html :  music_html_cb, 
    bat :  music_wget_cb 
};


casper.start('http://music.baidu.com');

var music_url = casper.cli.get(0);
var music_dst = casper.cli.get(1);
var dst_file_type = casper.cli.get("type") || 'xspf';

casper.then(function(){
 if( utils.isUndefined(music_url) ) return;
  write_music_file(music_url, music_dst, callback_info[dst_file_type]);
});

casper.run();

function music_xspf_cb(){
    return {
        head : '<?xml version="1.0" encoding="UTF-8"?>' +
'<playlist version="1" xmlns="http://xspf.org/ns/0/">' + 
    '<trackList>', 
        tail : '</trackList></playlist>', 
        item : function(m){
            return [ "<track>", 
                "<location>" + m["url"]  + "</location>", 
                "<image>" + m["album_img"]  + "</image>", 
                "<title>" + m["title"]  + "</title>", 
                "<creator>" + m["artist"]  + "</creator>", 
                "</track>"].join("\n");        
        }
    }
}

function music_html_cb(){
    return {
        head : '<html><head>' +
' <meta charset="utf-8">' + 
    '</head><body>', 
        tail : '</body></html>', 
        item : function(m){
            return [ '<a href="' + m["url"]  + '">',
                m["artist"]+'-'+m["title"],
                "</a><br/>"].join("");        
        }
    }

}

function music_wget_cb(){
    return function(m){ 
    return [ 'wget' , '-c', '"' + m["url"] + '"', 
        '-O', '"' + m["artist"]+'-'+m["title"]+'.'+m["format"] + '"' ].join(' ');
    }
}

function write_music_file(music_url, dst_file, cb){
    //if( utils.isUndefined(dst_file) ) return;
    var src_str = read_music_file(music_url);

    var s;
    if(cb){
    var callback = cb();
    var src = JSON.parse(src_str);
    var dst = new Array();
    var map_cb = callback.item || callback;
    for(var i in src){
        var s = map_cb(src[i]);
        dst.push(s);
    }

    s = dst.join("\n");
    if(callback.head) s = callback.head + "\n" + s;
    if(callback.tail) s =  s + "\n" + callback.tail;
    }else{
       s = src_str; 
    }

    if(dst_file){
    fs.write(dst_file, s, 'w');
    }else{
        console.log(s);
    }
}

function read_music_file(f) {
    var music_data = fs.read(f).match(/[^\r\n]+/g);
    var s = "[" + music_data.join(",\n") + "]";
    return s;
}
