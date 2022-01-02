#!/bin/bash
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# shellcheck disable=SC1090,SC1091
#   - disable "Can't follow non-constant source" this file is sourced from the internet
#
# download-and-execute-setup-script.sh
#   - downloads the mock-spacestation development environment setup script
#   - executes the downloaded script
#
# syntax: ./download-and-execute-setup-script.sh

# break on error
set -e

error_log() {
  echo "download-and-execute-setup-script.sh ERROR: ${1}" 1>&2;
}

info_log() {
  echo "download-and-execute-setup-script.sh INFO: ${1}"
}

# check for curl
if ! command -v curl &> /dev/null; then
    error_log "the 'curl' command could not be found. This script requires curl."
    exit 1
fi

# source setup script
repository_url="https://raw.githubusercontent.com/Azure/mock-spacestation"
branch_name="main"
script_dir=".devcontainer/library-scripts"
script_name="deploy-groundstation.sh"
script_uri="${repository_url}/${branch_name}/${script_dir}/${script_name}"

# download script
info_log "sourcing script with 'curl -O ${script_uri}'"
curl -O "${script_uri}"

# ensure script is executable
info_log "ensuring script is executable with 'chmod +x ${script_name}'"
chmod +x ${script_name}

# execute script with 'sourcr'
info_log "exeucting script with '. ${script_name}'"
. ./${script_name}
