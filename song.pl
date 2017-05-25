#!/usr/bin/perl
use Getopt::Std;
use FindBin;
use MIME::Base64;
use JSON::PP;
use Encode;
use Encode::Locale;
use Data::Dumper;
use File::Slurp qw/slurp/;
use Capture::Tiny qw/ capture_merged/;

our $DIR=$FindBin::RealBin;


my %opt;
getopt('clfNitzs', \%opt);
$opt{cookie} = $opt{c} || "$DIR/cookie.txt";
$opt{cookie} = slurp($opt{cookie}) if(-f $opt{cookie});
$opt{level} = $opt{l} || 0;
$opt{format} = $opt{f} || '';
$opt{not_save_collect} = $opt{N} // 1;
$opt{act} = $opt{t} // 'url'; 
$opt{msg} = $opt{z} || '';
my $song_id = $opt{i};
our $COLLECTED_SONG = read_collected_song($opt{s});

if($opt{act} eq 'url'){
    my $r = get_song_info($song_id, %opt);
    my $s = encode_json($r);
    print $s,"\n";
}else{
    collect_song($song_id, %opt);
    print "finish $opt{act} collect $song_id $opt{msg}\n";
}

sub read_collected_song {
    my ($f) = @_;
    $f ||= 'collected.txt';
    my $c = slurp($f);
    my @song = split /\n/, $c;
    s/\s+.*$// for @song;
    my %song = map { $_ => 1 } @song;
    return \%song;
}

sub get_song_info {
    my ($song_id, %opt) = @_;
    collect_song($song_id, act => 'add', cookie => $opt{cookie}) unless(exists $COLLECTED_SONG->{$song_id});
    my $info = get_song_base_info($song_id);
    my $f = select_song_file($info, format => $opt{format}, level => $opt{level});
    $f->{url}  = get_song_url($song_id, cookie => $opt{cookie}, rate =>$f->{kbps}, format=> $f->{format});
    $info->{$_} = $f->{$_} for keys(%$f);
    delete($info->{file_list});
    collect_song($song_id, act => 'del', cookie => $opt{cookie}) if($opt{not_save_collect} and ! exists $COLLECTED_SONG->{$song_id});
    return $info;
}

sub select_song_file {
    my ($base_info, %opt) = @_;
    my $files = $base_info->{file_list};
    $files = [ grep { $_->{format} eq $opt{format} } @$files ]  if($opt{format});
    $opt{level} = $#$files if($opt{level}>$#$files);
    return $files->[$opt{level}];
}

sub collect_song {
    my ($song_id, %opt)=@_;
    my @n = map { int(rand(10)) } ( 0 .. 23 );
    my $rand = join("", '0.', @n);

    my $x = $opt{act} eq 'add' ? 'collect' : 'deleteCollection';
    my $cmd = qq[curl -v "http://music.baidu.com/data/user/$x?.r=$rand" -H "Referer: http://music.baidu.com/song/$song_id" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:34.0) Gecko/20100101 Firefox/34.0" -H "Cookie: $opt{cookie}" -d "ids=$song_id&type=song&pay_type=2"];
    my $c =  capture_merged { `$cmd` };
    return $c;
    #my ($loc) =$c=~/ Location: (http.*?)\s+/s;
    #return $loc;
}

sub get_song_url {
    my ($song_id, %opt)=@_;
    my $cmd = qq[curl -v "http://yinyueyun.baidu.com/data/cloud/downloadsongfile?songIds=$song_id&rate=$opt{rate}&format=$opt{format}" -H "Referer: http://yinyueyun.baidu.com/?download=$song_id&pst=naga&fr=" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:34.0) Gecko/20100101 Firefox/34.0" -H "Cookie: $opt{cookie}"];
    my $c =  capture_merged { `$cmd` };
    my ($loc) =$c=~/ Location: (http.*?)\s+/s;
    return $loc;
}

sub get_song_base_info {
    my ($song_id) =@_;
    my $url = "http://musicmini.baidu.com/app/link/getLinks.php";
    my $param = {
        "songId"=>$song_id,
        "songsId"=>$song_id,
        "songsiId"=>$song_id,
        "songAppend"=>"",
        "linkType"=>1,
        "isLogin"=>1,
        "clientVer"=>"",
        "isHq"=>1,
        "isCloud"=>0,
        "hasMV"=>1,
        "noFlac"=>0,
        "rate"=>0
    };
    my $param_str = encode_json($param);
    my $param_s = encode_base64($param_str);
    $param_s=~s/\n//sg;
    my $cmd = qq[curl -s -d "param=$param_s" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:34.0) Gecko/20100101 Firefox/34.0" $url];
    my $c = `$cmd`;
    my $r=decode_json($c);
    return $r->[0];
}
