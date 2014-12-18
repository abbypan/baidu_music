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

getopt('upcmaotlfqiPN', \%opt);
$opt{t} //= 'xspf';
$opt{l} //= 0;
$opt{P} //= 1;
$opt{o} //='';
$opt{N} //= 1;

my $delete_id = 1;

#if(exists $opt{u} and exists $opt{p} and  exists $opt{c}){
    #system("casperjs $DIR/baidu_login.js $opt{u} $opt{p} $opt{c}");
#}

$opt{id} = $opt{i} || tmpnam();
if(exists $opt{m}){
    system("casperjs $DIR/id_music.js $opt{m} $opt{id}");
}elsif(exists $opt{a}){
    system("casperjs $DIR/id_album.js $opt{a} $opt{id}");
}elsif(exists $opt{q}){
    my $cmd = qq[casperjs $DIR/id_query.js "$opt{q}" "$opt{id}" --page="$opt{P}"];
    `$cmd`;
}elsif(exists $opt{i}){
    $delete_id = 0;
}

$opt{url} = tmpnam();
if($opt{t}=~/^(add|del)$/){
    system(qq[parallel --no-notice -a "$opt{id}" -C ' ' perl $DIR/song.pl -c "$opt{c}" -i {1} -d $opt{t} -m "{2}"]);
}else{
    my $cmd=qq[parallel --no-notice -a "$opt{id}" -C ' ' perl $DIR/song.pl -N "$opt{N}" -l $opt{l} -c "$opt{c}" -i {1}];
    $cmd.=" -f $opt{f}" if($opt{f});
    $cmd.=qq[ > $opt{url}];
    `$cmd`;

    my $cmd=qq[casperjs $DIR/info_write.js "$opt{url}" "$opt{o}" --type="$opt{t}"];
    system($cmd);
}
