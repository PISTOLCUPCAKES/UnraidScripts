#!/bin/bash

# find our working directory and name
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# redireout output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

# shellcheck disable=SC2154
echo "sonarr_eventtype: ${sonarr_eventtype}"
# shellcheck disable=SC2154
echo "sonarr_isupgrade: ${sonarr_isupgrade}"
# shellcheck disable=SC2154
echo "sonarr_moviefile_sourcepath: ${sonarr_moviefile_sourcepath}"
# shellcheck disable=SC2154
echo "sonarr_moviefile_sourcefolder: ${sonarr_moviefile_sourcefolder}"