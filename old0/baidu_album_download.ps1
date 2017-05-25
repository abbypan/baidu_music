$u=$args[0]
$m = $u -replace ".*/","";

$dst = $args[1]
if(!$dst){ $dst = $m + '.ps1'; }

$id = $m+'.id'
casperjs baidu_music_album.js $u $id

$url = $m+'.url'
casperjs baidu_music_url.js $id $url

$dst_utf8 = $m+'.utf8.ps1'
casperjs baidu_music_write.js $url $dst_utf8 powershell
cat $dst_utf8 -Encoding utf8 > $dst

rm $dst_utf8
rm $id
rm $url
