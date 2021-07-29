#!/bin/bash

# find our working directory and name
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# redireout output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

# shellcheck disable=SC2154
echo "radarr_eventtype: ${radarr_eventtype}"
# shellcheck disable=SC2154
echo "radarr_isupgrade: ${radarr_isupgrade}"
# shellcheck disable=SC2154
echo "radarr_moviefile_sourcepath: ${radarr_moviefile_sourcepath}"
# shellcheck disable=SC2154
echo "radarr_moviefile_sourcefolder: ${radarr_moviefile_sourcefolder}"