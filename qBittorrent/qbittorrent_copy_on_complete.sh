#!/bin/bash -eu

# ------------------------------------------------------------------------------
# Script        | qbittorrent_copy_on_complete.sh
# Description   | Script to copy a completed torrent to another directory
#                   and resume the torrent
# qbittorrent command: qbittorrent_copy_on_complete.sh '%I' '%R'
#
# Requires:
#               jq - https://stedolan.github.io/jq/
# ------------------------------------------------------------------------------


function error {
    echo "ERROR:  ${1:-}"
    exit 1
}

####################################
#    ENV SETUP & VERIFICATION      #
####################################

# get script parameters
readonly TORRENT_HASH="$1"
readonly TORRENT_PATH="$2"

# Verify parameters were provided
if [ -z "${TORRENT_HASH}" ]; then error "Torrent Hash not provided"; fi;
if [ -z "${TORRENT_PATH}" ]; then error "Torrent Path not provided"; fi;

# get script location so we know where to find qbittorrent.env, then source it
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

# shellcheck source=qbittorrent.env
. "${SCRIPT_DIR}"/qbittorrent.env

# Verify qbittorrent.env was sourced correctly
if [ -z "${QBIT_HOST}" ];        then error "QBIT_HOST is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_WEBUI_PORT}" ];  then error "QBIT_WEBUI_PORT is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_WEBUI_USER}" ];  then error "QBIT_WEBUI_USER is not set. Is qbittorrent.env in the same directory as this script?"; fi;
# not checking QBIT_WEBUI_PASS to allow for bypassed authentication from localhost/LAN
if [ -z "${QBIT_CATEGORIES}" ];  then error "QBIT_CATEGORIES is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_COPY_TO_DIR}" ]; then error "QBIT_COPY_TO_DIR is not set. Is qbittorrent.env in the same directory as this script?"; fi;

# setup API root address
readonly QBIT_ADDRESS="http://${QBIT_HOST}:${QBIT_WEBUI_PORT}"
readonly QBIT_API_ROOT="${QBIT_ADDRESS}/api/v2"

# make sure jq is available. It is necessary for parsing json responses
if ! [ -x "$(command -v jq)" ]; then error "jq is not in the path or installed"; fi;


####################################
#             API AUTH             #
####################################

# login to qbittorrent and save the authentication cookie for future use
readonly AUTH_COOKIE=$(curl --silent --fail --show-error --header "Referer: ${QBIT_ADDRESS}" --cookie-jar - --data "username=${QBIT_WEBUI_USER}&password=${QBIT_WEBUI_PASS}" --request GET "${QBIT_API_ROOT}/auth/login")


####################################
#   GET CATEGORY AND PROCEED/EXIT  #
####################################

# get the category for this torrent
readonly TORRENT_CATEGORY=$(echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request GET "${QBIT_API_ROOT}/torrents/info?hashes=${TORRENT_HASH}" | jq --raw-output .[0].category)

# check to see if the torrents category is in the list of categories to process, if not then exit
PROCEED=false
for c in "${QBIT_CATEGORIES[@]}"
do
    if [ "${c}" = "${TORRENT_CATEGORY}" ]
    then
        PROCEED=true
    fi
done

if [ "${PROCEED}" = "false" ]
then
    echo "This torrent's category is not in the list of categories to process. Skipping..."
    exit
fi


####################################
#              COPY                #
####################################

cp -r "${TORRENT_PATH}" "${QBIT_COPY_TO_DIR}"



# get torrent category
# jq manual: https://stedolan.github.io/jq/manual/#Basicfilters



# if [ $(basename ${save_path}) == "arr" ] ????
# or: if category in (radarr, sonarr) ???
#TODO
# copy torrent to /data/3-copied/arr

# Set torrent share limit
# https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-share-limit


####################################
#                                  #
####################################