#!/usr/bin/perl 

my ($music_file) = @ARGV;
$music_file ||= 'baidu_music.txt';

my $login_info = 'baidu_login.txt';
print "read login info : $login_info\n";
open my $fh, '<', $login_info;
my ($usr, $passwd) = <$fh>;
chomp($usr);
chomp($passwd);
close $fh;

my $cookie_file = "baidu_cookie.txt";
system("casperjs baidu_login.js $usr $passwd $cookie_file");

print "read music file : $music_file\n\n";
open my $fh, '<', $music_file;
while(<$fh>){
    chomp;
    system("casperjs baidu_collect_song.js $cookie_file $_");
}
close $fh;
