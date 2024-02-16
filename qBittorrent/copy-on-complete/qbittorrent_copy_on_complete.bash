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

# find our working directory & script name
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_DIR

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# redireout output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

function error {
    echo "ERROR:  ${1:-}"
    exit 1
}

echo "Starting $(basename "${BASH_SOURCE[0]}")"
echo "TORRENT_HASH: ${TORRENT_HASH}"
echo "TORRENT_PATH: ${TORRENT_PATH}"


####################################
#    ENV SETUP & VERIFICATION      #
####################################

# Verify parameters were provided
if [ -z "${TORRENT_HASH}" ]; then error "Torrent Hash not provided"; fi;

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
AUTH_COOKIE=$(curl --silent --fail --show-error --header "Referer: ${QBIT_ADDRESS}" --cookie-jar - --data "username=${QBIT_WEBUI_USER}&password=${QBIT_WEBUI_PASS}" --request POST "${QBIT_API_ROOT}/auth/login")
readonly AUTH_COOKIE


####################################
#   GET CATEGORY AND PROCEED/EXIT  #
####################################

# get the torrent info
echo "Retrieving torrent info..."
TORRENT_INFO=$(echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request GET "${QBIT_API_ROOT}/torrents/info?hashes=${TORRENT_HASH}")
readonly TORRENT_INFO

# parse json response to get torrent category
TORRENT_CATEGORY=$(echo "${TORRENT_INFO}" | jq --raw-output .[0].category)
readonly TORRENT_CATEGORY

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

if [ -n "${TORRENT_PATH}" ] # TORRENT_PATH was provided
then
    # -r : recursive
    # -p : preserve attributes (mode/persmissions, ownership, timestamps)
    # --link : hard link instead of copying
    echo "Copying recursively from ${TORRENT_PATH} to ${QBIT_COPY_TO_DIR}..."
    cp -rp --link "${TORRENT_PATH}" "${QBIT_COPY_TO_DIR}"
else
    echo "Torrent path was not provided, using content_path from torrent info"
    TORRENT_CONTENT_PATH=$(echo "${TORRENT_INFO}" | jq --raw-output .[0].content_path)
    readonly TORRENT_CONTENT_PATH
    echo "Copying recursively from ${TORRENT_CONTENT_PATH} to ${QBIT_COPY_TO_DIR}..."
    cp -rp --link "${TORRENT_CONTENT_PATH}" "${QBIT_COPY_TO_DIR}"
fi


####################################
#    SET SHARE LIMITES & RESUME    #
####################################

# set limits
echo "Setting share limits..."
echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request POST "${QBIT_API_ROOT}/torrents/setShareLimits" --data-urlencode "hashes=${TORRENT_HASH}" --data-urlencode "ratioLimit=${QBIT_SEED_RATIO}" --data-urlencode "seedingTimeLimit=${QBIT_SEED_TIME}" --data-urlencode "inactiveSeedingTimeLimit=${QBIT_INACTIVE_SEEDING_TIME_LIMIT}"

#resume torrent
echo "Resuming torrent..."
echo "${AUTH_COOKIE}" | curl --silent --fail --show-error --cookie - --request POST "${QBIT_API_ROOT}/torrents/resume" --data-urlencode "hashes=${TORRENT_HASH}"


echo "Finished $(basename "${BASH_SOURCE[0]}")"
