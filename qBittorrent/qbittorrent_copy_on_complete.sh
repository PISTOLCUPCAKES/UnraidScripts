#!/bin/bash

set -e

# ------------------------------------------------------------------------------
# Script        | qbittorrent_copy_on_complete.sh
# Description   | Script to copy a completed torrent to another directory
#                   and resume the torrent
# qbittorrent command: qbittorrent_copy_on_complete.sh '%R' '%D'
# ------------------------------------------------------------------------------

####################################
#                                  #
####################################

####################################
#           ENV SETUP              #
####################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

# shellcheck source=qbittorrent.env
. "${SCRIPT_DIR}"/qbittorrent.env

readonly TORRENT_PATH="$1"
readonly SAVE_PATH=%D

####################################
#         VERIFY OPTIONS           #
####################################


####################################
#              COPY                #
####################################

cp -r "${TORRENT_PATH}" "${COPY_TO_DIR}"



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


