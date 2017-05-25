#!/usr/bin/perl
use Getopt::Std;
use FindBin;

our $DIR=$FindBin::RealBin;

getopt('upcmaotl', \%opt);
$opt{t} ||= 'xspf';
$opt{l} ||= 0;

if(exists $opt{u} and exists $opt{p} and  exists $opt{c}){
    system("casperjs $DIR/baidu_login.js $opt{u} $opt{p} $opt{c}");
}

if(exists $opt{m}){
    $opt{id} = "$opt{m}.id";
    system("casperjs $DIR/baidu_music_id.js $opt{m} $opt{id}");
}elsif(exists $opt{a}){
    $opt{id} = "$opt{a}.id";
    $opt{id}=~s#^.*/##;
    system("casperjs $DIR/baidu_music_album.js $opt{a} $opt{id}");
}

if($opt{t} eq 'collect'){
    system("casperjs $DIR/baidu_music_collect.js $opt{c} $opt{id}");
}else{
    $opt{url} = "$opt{id}.url";
    system("casperjs $DIR/baidu_music_url.js $opt{id} $opt{url} $opt{l}");
    $opt{o} ||= "$opt{id}.$opt{t}";
    system("casperjs $DIR/baidu_music_write.js $opt{url} $opt{o} $opt{t}"); 
}

unlink($opt{id});
unlink($opt{url});
