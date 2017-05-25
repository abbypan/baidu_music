#!/usr/bin/perl
use strict;
use warnings;

use Web::Scraper;
use Data::Dumper;
use Encode::Locale;
use Encode;

my ( $album_url ) = @ARGV;

main_album( $album_url );

#get_album_info('http://music.baidu.com/album/8846541');
#get_song_info('http://music.baidu.com/song/8885047');

sub main_album {
  my ( $album_url ) = @_;
  print "get_album_info: $album_url\n";
  my $album_inf = get_album_info( $album_url );
  my $dir = encode( locale => decode( "utf8", "$album_inf->{singer}-$album_inf->{album_name}" ) );
  mkdir $dir;
  my $i = 1;
  for my $s ( @{ $album_inf->{song} } ) {
    next unless($s->{url} and $s->{song_title});
    my $u = "http://music.baidu.com$s->{url}";
    print "get_song_info: $u\n";
    my $sr         = get_song_info( $u );
    my $j          = sprintf( "%02d", $i );
    my ( $suffix ) = $sr->{song_url} =~ m#\.([^\.\?]+?)\?xcode=#s;
    my $song_file  = "$album_inf->{singer}-$album_inf->{album_name}/$j.$sr->{song_title}.$suffix";
    print "download song: $song_file\n";
    my $cmd = encode( locale => decode( 'utf8', qq[curl -C - "$sr->{song_url}" -o "$song_file"] ) );
    system($cmd);
    $i++;
  }
} ## end sub main_album

sub get_song_info {
  my ( $song_url ) = @_;
  my $c            = `curl -s "$song_url"`;
  my $s            = scraper {
    process_first '//span[@class="author_list"]', singer     => '@title';
    process_first '//span[@class="name"]',        song_title => 'TEXT';
    process_first '//input[@id="songlink"]',      song_url   => '@value';
  };
  my $r = $s->scrape( $c );

#print Dumper($r);
  return $r;
}

sub get_album_info {
  my ( $album_url ) = @_;
  my $c             = `curl -s "$album_url"`;
  my $s             = scraper {
    process_first '//h2[@class="album-name"]',    album_name => 'TEXT';
    process_first '//span[@class="author_list"]', singer     => '@title';
    process '//div[@class="body "]//ul//li',
      'song[]' => scraper {
      process_first '//span[@class="song-title "]//a', url => '@href', song_title => 'TEXT';
      };
  };
  my $r = $s->scrape( $c );

#print Dumper($r);

  return $r;
}
