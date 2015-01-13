#!/usr/bin/perl

use Data::Dumper;
use Encode::Locale;
use Encode;
use MP3::Info;
use WWW::Mechanize::Firefox;
use Web::Scraper;
use utf8;

our $RETRY = 5;
my @music_type = qw/flac mp3/;

my $browser = init_firefox_agent();

my ($obj) = @ARGV;
$obj = '.' if ( !$obj );

my @music_files;
if ( -f $obj ) {
    @music_files = ($obj);
}
else {
    for my $t (@music_type) {
        push @music_files, glob("$obj/*.$t");
    }
}

for my $f (@music_files) {
    read_and_collect_song( $browser, $f );
}

sub read_and_collect_song {
    my ( $browser, $file ) = @_;

    my $info = read_song_info($file);
    return unless ( $info->{title} );

    my $id = search_baidu_song( $browser, $info );
    return unless ($id);

    collect_baidu_song( $browser, $id );
}

sub read_mp3_info {
    my ($filename) = @_;

    my $info = get_mp3tag($filename);
    for my $k (qw/title artist album/) {
        my $g_k = uc $k;
        $info->{$k} = $info->{$g_k};
    }
    return $info;
}

sub read_flac_info {
    my ($filename) = @_;
    my %info;

    for my $k (qw/title artist album/) {
        my $v = `metaflac --show-tag=$k "$filename"`;
        $v =~ s/^$k=//i;
        chomp($v);
        $info{$k} = decode( locale => $v );
    }

    return \%info;
}

sub read_song_info {
    my ($filename) = @_;
    print "read file : $filename\n";

    return read_flac_info($filename) if ( $filename =~ /\.flac$/ );
    return read_mp3_info($filename)  if ( $filename =~ /\.mp3$/ );
    return $data;
}

sub search_baidu_song {
    my ( $browser, $song ) = @_;

    $browser->get("http://music.baidu.com/");

    my $key = $song->{title};
    $key .= " $song->{artist}" if ( $song->{artist} );
    print encode( locale => "search song : $key\n" );
    $browser->submit_form( with_fields => { key => $key } );

    my (@div) =
      extract_firefox_xpath( $browser, '//div[@class="song-item clearfix"]' );
    (@div) =
      extract_firefox_xpath( $browser, '//div[@class="song-opera clearfix"]' )
      if ( !@div );
    return unless (@div);

    for my $div (@div) {
        my $r = extract_baidu_song( $div->{innerHTML} );
        next unless ( $r->{title} eq $song->{title} );
        next unless ( $song->{artist} and $r->{artist} eq $song->{artist} );
        return $r->{id};
    }
}

sub extract_baidu_song {
    my ($div_html) = @_;

    my $scraper = scraper {
        process_first '//a', 'id' => '@href', 'title' => '@title';
        process_first '//span[@class="author_list"]', 'artist' => '@title';
    };
    my $r = $scraper->scrape($div_html);

    $r->{id} =~ s#/song/##;
    $r->{id} =~ s/#.*//;
    return $r;
}

sub collect_baidu_song {
    my ( $browser, $song_id ) = @_;
    my $url = "http://music.baidu.com/song/$song_id";
    print "visit : $url\n";
    $browser->get($url);

    my $xpath = qq#//a[contains(\@class, 'btn btn-b  song-collect')]#;
    my $btn = extract_firefox_xpath( $browser, $xpath );
    if ( !$btn ) {
        my $xpath = qq#//a[\@data-btndata='{"ids":"$song_id","type":"song"}'#;
        $btn = extract_firefox_xpath( $browser, $xpath );
    }

    return unless ($btn);

    print encode( locale => "collect song : $song_id\n" );

    my $is_collected = $btn->{innerHTML} =~ />已收藏</ ? 1 : 0;
    return if ($is_collected);

    eval { $browser->click( { xpath => $xpath, synchronize => 0 } ); };
}

### {{{
sub init_firefox_agent {
    my ($url) = @_;
    my $mech = WWW::Mechanize::Firefox->new(
        ssl_opts  => { verify_hostname => 0, },
        autoclose => 1,
        bufsize   => 1024 * 1024 * 5,
    );
    $mech->allow( images => 0, plugins => 0 );
    $mech->repl->repl->client->{telnet}->timeout(20);
    if ($url) {
        $mech->add_header( 'Referer' => $url );
        $mech->get($url);
    }
    return $mech;
}

sub extract_firefox_xpath {
    my ( $mech, $xpath, $innerHTML ) = @_;
    my @xp;
    for ( 1 .. $RETRY ) {
        eval { @xp = $mech->xpath($xpath); };
        if ($innerHTML) {
            @xp = grep { $_->{innerHTML} =~ /$innerHTML/s } @xp;
        }
        last if (@xp);
        sleep 1;

        #print "try $_ : extract $xpath";
    }
    return wantarray ? @xp : $xp[0];
}

###  }}}
