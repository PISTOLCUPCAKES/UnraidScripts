############
#  Ubuntu  #
############
# %N	ubuntu-18.04.5-desktop-amd64.iso
# %F	/data/2-complete/arr/ubuntu-18.04.5-desktop-amd64.iso
# %R	/data/2-complete/arr/ubuntu-18.04.5-desktop-amd64.iso
# %D	/data/2-complete/arr
# %C	1
# %Z	2193522688
# %T	https://torrent.ubuntu.com/announce
# %I	94a315e2cf8015b2f635d79aab592e6db557d5ea

############
#  Mayans  #
############
# %N	Mayans.M.C.S03E03.Overreaching.Dont.Pay.1080p.AMZN.WEBRip.DDP5.1.x264-NTb[rartv]
# %F	/data/2-complete/arr/Mayans.M.C.S03E03.Overreaching.Dont.Pay.1080p.AMZN.WEBRip.DDP5.1.x264-NTb[rarbg]
# %R	/data/2-complete/arr/Mayans.M.C.S03E03.Overreaching.Dont.Pay.1080p.AMZN.WEBRip.DDP5.1.x264-NTb[rarbg]
# %D	/data/2-complete/arr
# %C	3
# %Z	4164683787
# %T	udp://9.rarbg.to:2760
# %I	d0bdb9e003eb5333a3b0c4ad51adecf10524ccbd

#!/bin/sh

save_path=%D


category="$(basename $1)"
torrent_hash="$2"
torrent_name="$3"




host="http://localhost:8280"
username="admin"
password=""


# https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-list

# get auth cookie
cookie=$(curl --silent --fail --show-error --header "Referer: $host" --cookie-jar - --request GET "$host/api/v2/auth/login?username=$username&password=$password")

# get torrents info (just an example of using cookie)
echo "$cookie" | curl --silent --fail --show-error --cookie - --request GET "$host/api/v2/torrents/info"



# if [ $(basename ${save_path}) == "arr" ] ????
# or: if category in (radarr, sonarr) ???
#TODO
# copy torrent to /data/3-copied/arr


