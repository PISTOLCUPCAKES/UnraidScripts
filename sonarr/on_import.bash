#!/bin/bash

# find our working directory and name
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# redirect output
exec >> "${SCRIPT_DIR}/${SCRIPT_NAME}.log"
exec 2>&1

# delete the episode we've just imported
# shellcheck disable=SC2154
echo "Removing file ${sonarr_episodefile_sourcepath}"
rm -rf "${sonarr_episodefile_sourcepath}"

# shellcheck disable=SC2154
numfiles=$(find "${sonarr_episodefile_sourcefolder}" -type f | wc -l)

if [ "${numfiles}" -eq 0 ]
then
    echo "No files remain. Removing directory ${sonarr_episodefile_sourcefolder}"
    rm -rf "${sonarr_episodefile_sourcefolder}"
fi