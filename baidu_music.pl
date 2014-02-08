#!/usr/bin/perl
use Getopt::Std;
use FindBin;
use Encode::Locale;
use Encode;
use Data::Dumper;

our $DIR=$FindBin::RealBin;

getopt('upcmaotlfqiP', \%opt);
$opt{t} //= 'xspf';
$opt{l} //= 0;
$opt{f} //='';
$opt{P} //= 1;

my $delete_id = 1;

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
    #$opt{q} = encode(locale => $opt{q});
    my $cmd = qq[casperjs $DIR/baidu_music_query.js "$opt{q}" "$opt{id}" --page="$opt{P}"];
    `$cmd`;
}elsif(exists $opt{i}){
   $opt{id} = $opt{i}; 
   $delete_id = 0;
}

if($opt{t} eq 'collect'){
    system("casperjs $DIR/baidu_music_collect.js $opt{c} $opt{id}");
}else{
    $opt{url} = "$opt{id}.url";
    system(qq[casperjs $DIR/baidu_music_url.js $opt{id} $opt{url} --level="$opt{l}" --format="$opt{f}"]);
    my $cmd=qq[casperjs $DIR/baidu_music_write.js $opt{url} "$opt{o}" --type="$opt{t}"];
    `$cmd`;
}

unlink($opt{id}) if($delete_id);
unlink($opt{url});
