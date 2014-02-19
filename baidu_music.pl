#!/usr/bin/perl
use Getopt::Std;
use FindBin;
use Encode::Locale;
use Encode;
use Data::Dumper;
    use File::Temp qw/ :POSIX /;

binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

our $DIR=$FindBin::RealBin;

getopt('upcmaotlfqiP', \%opt);
$opt{t} //= 'xspf';
$opt{l} //= 0;
$opt{f} //='';
$opt{P} //= 1;
$opt{o} //='';

my $delete_id = 1;

if(exists $opt{u} and exists $opt{p} and  exists $opt{c}){
    system("casperjs $DIR/baidu_login.js $opt{u} $opt{p} $opt{c}");
}

$opt{id} = $opt{i} || tmpnam();
if(exists $opt{m}){
    system("casperjs $DIR/baidu_music_id.js $opt{m} $opt{id}");
}elsif(exists $opt{a}){
    system("casperjs $DIR/baidu_music_album.js $opt{a} $opt{id}");
}elsif(exists $opt{q}){
    my $cmd = qq[casperjs $DIR/baidu_music_query.js "$opt{q}" "$opt{id}" --page="$opt{P}"];
    `$cmd`;
}elsif(exists $opt{i}){
    $delete_id = 0;
}

$opt{url} = tmpnam();
if($opt{t} eq 'collect'){
    system("casperjs $DIR/baidu_music_collect.js $opt{c} $opt{id}");
}else{
    system(qq[casperjs $DIR/baidu_music_url.js $opt{id} $opt{url} --level="$opt{l}" --format="$opt{f}"]);
    my $cmd=qq[casperjs $DIR/baidu_music_write.js "$opt{url}" "$opt{o}" --type="$opt{t}"];
    system($cmd);
}
