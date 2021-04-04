#!/bin/bash -eu

# ------------------------------------------------------------------------------
# Script        | qbittorrent_copy_on_complete.bash
# Description   | Script to copy a completed torrent to another directory
#                   and resume the torrent
# qbittorrent command: /data/scripts/qbittorrent_copy_on_complete.bash "%I" "%R"
#
# Requires:
#               jq - https://stedolan.github.io/jq/
# ------------------------------------------------------------------------------

# get script parameters
readonly TORRENT_HASH="$1"
readonly TORRENT_PATH="$2"

# find our working directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# redireout output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

function error {
    echo "ERROR:  ${1:-}"
    exit 1
}

echo "Starting $(basename "${BASH_SOURCE[0]}")"


####################################
#    ENV SETUP & VERIFICATION      #
####################################

# Verify parameters were provided
if [ -z "${TORRENT_HASH}" ]; then error "Torrent Hash not provided"; fi;
if [ -z "${TORRENT_PATH}" ]; then error "Torrent Path not provided"; fi;

# shellcheck source=qbittorrent.env
. "${SCRIPT_DIR}"/qbittorrent.env

# Verify qbittorrent.env was sourced correctly
if [ -z "${QBIT_HOST}" ];        then error "QBIT_HOST is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_WEBUI_PORT}" ];  then error "QBIT_WEBUI_PORT is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_WEBUI_USER}" ];  then error "QBIT_WEBUI_USER is not set. Is qbittorrent.env in the same directory as this script?"; fi;
# not checking QBIT_WEBUI_PASS to allow for bypassed authentication from localhost/LAN
if [ -z "${QBIT_CATEGORIES}" ];  then error "QBIT_CATEGORIES is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_COPY_TO_DIR}" ]; then error "QBIT_COPY_TO_DIR is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_SEED_RATIO}" ]; then error "QBIT_SEED_RATIO is not set. Is qbittorrent.env in the same directory as this script?"; fi;
if [ -z "${QBIT_SEED_TIME}" ]; then error "QBIT_SEED_TIME is not set. Is qbittorrent.env in the same directory as this script?"; fi;

# setup API root address
readonly QBIT_ADDRESS="http://${QBIT_HOST}:${QBIT_WEBUI_PORT}"
readonly QBIT_API_ROOT="${QBIT_ADDRESS}/api/v2"

# make sure jq is available. It is necessary for parsing json responses
if ! [ -x "$(command -v jq)" ]; then error "jq is not in the path or installed"; fi;


####################################
#             API AUTH             #
####################################

# login to qbittorrent and save the authentication cookie for future use
echo "Logging into qbittorrent..."
readonly AUTH_COOKIE=$(curl --silent --fail --show-error --header "Referer: ${QBIT_ADDRESS}" --cookie-jar - --data "username=${QBIT_WEBUI_USER}&password=${QBIT_WEBUI_PASS}" --request GET "${QBIT_API_ROOT}/auth/login")


####################################
#   GET CATEGORY AND PROCEED/EXIT  #
####################################

# get the category for this torrent
echo "Retrieving torrent category..."
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

#recursive copy and preserve attributes
echo "Coppying torrent..."
cp -rp "${TORRENT_PATH}" "${QBIT_COPY_TO_DIR}"


####################################
#    SET SHARE LIMITES & RESUME    #
####################################

# set limits
echo "Setting share limits..."
echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request GET "${QBIT_API_ROOT}/torrents/setShareLimits?hashes=${TORRENT_HASH}&ratioLimit=${QBIT_SEED_RATIO}&seedingTimeLimit=${QBIT_SEED_TIME}"

#resume torrent
echo "Resuming torrent..."
echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request GET "${QBIT_API_ROOT}/torrents/resume?hashes=${TORRENT_HASH}"


echo "Finished $(basename "${BASH_SOURCE[0]}")"
