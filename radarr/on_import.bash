#!/bin/bash

# find our working directory and name
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# redireout output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

# delete the episode we've just imported
# shellcheck disable=SC2154
echo "Removing file ${radarr_moviefile_sourcepath}"
rm -rf "${radarr_moviefile_sourcepath}"

# shellcheck disable=SC2154
numfiles=$(find "${radarr_moviefile_sourcefolder}" -type f | wc -l)

if [ "${numfiles}" -eq 0 ]
then
    echo "No files remain. Removing directory ${radarr_moviefile_sourcefolder}"
    rm -rf "${radarr_moviefile_sourcefolder}"
fi