baidu_music
=================

- 将指定音乐 批量导入 百度音乐 收藏，省得私人音乐频道猜来猜去
- 获取指定专辑的音乐信息
- 批量下载音乐
- 批量生成vlc可用的xspf列表文件，在线播放音乐

参考：[百度音乐助手](https://greasyfork.org/en/scripts/483-%E7%99%BE%E5%BA%A6%E9%9F%B3%E4%B9%90%E5%8A%A9%E6%89%8B)

cookie信息取自浏览器，例如firefox里可以安装httpfox直接copy value

# baidu_music.pl

```
#根据music.txt生成xspf（播放列表）
perl baidu_music.pl -m music.txt -t xspf -o vlc.xspf -c cookie.txt

#根据music.txt生成bat（wget批量下载）
perl baidu_music.pl -m music.txt -t bat -o wget.bat -c cookie.txt

#根据music.txt生成html网页(浏览器打开html后down them all下载) 
perl baidu_music.pl -m music.txt -t html -o web.html -c cookie.txt

#根据music.txt生成online听歌数据
perl baidu_music.pl -m music.txt -o online.json -c cookie.txt

#根据id生成xspf
perl baidu_music.pl -i music_id.txt -t xspf -o web.xspf -c cookie.txt

#根据album_url生成xspf
perl baidu_music.pl -a http://music.baidu.com/album/177366 -t xspf -o lzs.xspf -c cookie.txt
perl baidu_music.pl -a http://music.baidu.com/film/70663646 -t xspf -o lzs.xspf -c cookie.txt

#根据指定关键字查询音乐
perl baidu_music.pl -q "小楼古风精选 Finale" -t xspf -o finale.xspf -c cookie.txt
perl baidu_music.pl -q "河图" -P 3 -t xspf -o ht.xspf -c cookie.txt
```

参数说明：
```
c : 指定cookie文件，或cookie文本内容

m : 音乐文件
a : 专辑url，例如 http://music.baidu.com/album/177366
q : 查询音乐的关键字
P : 查询音乐，取其中第 P 页的结果

i : 音乐id文件

o : 目标文件，不指定则直接输出到stdout
t : 目标动作类型
    xspf(播放列表)，wget(wget下载文件)，html(网页)，online(在线json)
    add(添加收藏)，del(取消收藏)

l : 音乐文件音质，0 (最好) ~ 3 (最差)，默认取0
f : 音乐文件格式(flac/mp3)
N : 查询完音乐url，不收藏
```

# song.pl

例如获取[辛晓琪《俩俩相忘》](http://music.baidu.com/song/246881/) 的flac音乐文件信息，并收藏

perl song.pl -i 246881 -N 0 -f flac -c cookie.txt

结合parallel可实现批量操作
```
#指定id.txt，批量 收藏/取消收藏
parallel --no-notice -a id.txt -C ' ' perl song.pl -c cookie.txt -i {1} -d add -m "{2}"
parallel --no-notice -a id.txt -C ' ' perl song.pl -c cookie.txt -i {1} -d del -m "{2}"

#指定id.txt，批量查询音乐信息，写入info.txt
parallel --no-notice -a id.txt -C ' ' perl song.pl -c cookie.txt -i {1} > info.txt
```

## 参数说明
```
i : 音乐id
t : 动作，默认为 url(查询)，此外为 add(添加收藏)、del(取消收藏)
z : 收藏/取消收藏完成时，补充输出的消息

c : 同baidu_music.pl
l : 同baidu_music.pl
f : 同baidu_music.pl
N : 同baidu_music.pl
```

处理过程
--------

album_url（专辑url） / music.txt （每行歌名在前，歌手在后） / 查询关键字

-> id.txt （音乐id）

-> info.txt （获取音乐信息） / 批量添加收藏 / 批量取消收藏

->  xspf （播放列表）/ bat （调用wget批量下载）/ html （在浏览器访问下载) / online （在线听歌需要的json信息)

动作分解
--------


## 指定歌名(艺人)查询音乐id

music.txt 为音乐列表，一行一首，歌名在前（必填），歌手在后（可不填）

结果批量写入id.txt，如果不指定id.txt，则输出到stdout

```
casperjs id_music.js music.txt id.txt
casperjs id_music.js music.txt
```

## 指定关键字查询多首音乐id

结果写入id.txt，如果不指定id.txt，则输出到stdout

page : 取第几页（默认是取第1页）

```
casperjs id_query.js "小楼古风精选 Finale" id.txt
casperjs id_query.js "小楼古风精选 Finale"
casperjs id_query.js "小楼古风精选 Finale" --page=2
```


## 获取专辑音乐id

结果写入id_swd3e.txt，如果不指定id_swd3e.txt，则输出到stdout
```
casperjs id_album.js http://music.baidu.com/album/23319159 id_swd3e.txt
```

## 根据info.txt，生成目标文件

```
#指定info.txt，生成vlc在线播放列表
casperjs info_write.js info.txt vlc.xspf --type=xspf

#指定info.txt，生成html在线url列表(浏览器打开html后down them all下载) 
casperjs info_write.js info.txt web.html --type=html

#指定info.txt，生成wget下载脚本
casperjs info_write.js info.txt wget.bat  --type=wget

#指定info.txt，输出online听歌的json信息
casperjs info_write.js info.txt online.json --type=online
```

# 安装说明

需要安装

[phantomjs](http://phantomjs.org/)

[casperjs](http://casperjs.org/)

wget

curl

parallel

# 问题

目前 artist 匹配较严，如果查"水晶 任贤齐"，取回结果为"水晶 任贤齐/徐怀珏"，是不做收藏的
