#!/usr/bin/perl
use Getopt::Std;
use FindBin;

our $DIR=$FindBin::RealBin;

getopt('upcmaotlfqi', \%opt);
$opt{t} ||= 'xspf';
$opt{l} ||= 0;
$opt{f} ||='';
$opt{i} ||= 1;

if(exists $opt{u} and exists $opt{p} and  exists $opt{c}){
    system("casperjs $DIR/baidu_login.js $opt{u} $opt{p} $opt{c}");
}

if(exists $opt{m}){
    $opt{id} = $opt{o} ? "$opt{o}.id" : "$opt{m}.id";
    system("casperjs $DIR/baidu_music_id.js $opt{m} $opt{id}");
}elsif(exists $opt{a}){
    $opt{id} = "$opt{a}.id";
    $opt{id}=~s#^.*/##;
    system("casperjs $DIR/baidu_music_album.js $opt{a} $opt{id}");
}elsif(exists $opt{q}){
    $opt{id} = $opt{o} ? "$opt{o}.id" : "query-".int(rand(10000000)).".id";
    system(qq[casperjs $DIR/baidu_music_query.js "$opt{q}" "$opt{id}" --page=$opt{i}]);
}

if($opt{t} eq 'collect'){
    system("casperjs $DIR/baidu_music_collect.js $opt{c} $opt{id}");
}else{
    $opt{url} = "$opt{id}.url";
    system(qq[casperjs $DIR/baidu_music_url.js $opt{id} $opt{url} --level=$opt{l} --format="$opt{f}"]);
    #$opt{o} ||= "$opt{id}.$opt{t}";
    system(qq[casperjs $DIR/baidu_music_write.js $opt{url} "$opt{o}" --type=$opt{t}]); 
}

unlink($opt{id});
unlink($opt{url});
