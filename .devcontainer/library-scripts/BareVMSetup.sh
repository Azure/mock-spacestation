#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Used on a blank VM Sets up the local environment to emulate connectivity to the Space Station.
# Syntax: ./BareVMSetup.sh

echo "Starting Mock Space Station Configuration (v $VERSION)." >> /home/${USER}/Mock-SpaceStation-AzureVmSetup.txt
USER="azureuser"
SPACE_NETWORK_NAME="spacedev-vnet-spacestation"
STATION_SSH_KEY="/home/${USER}/.ssh/id_rsa_spaceStation"
STATION_CONTAINER_NAME="spacedev-spacestation"
STATION_DOCKER_FILE="/home/${USER}/Dockerfile.SpaceStation"
GROUND_STATION_DIR="/home/${USER}/groundstation"
LOG_DIR="/home/${USER}/logs"
SPACE_STATION_DIR="/home/${USER}/spacestation"
VERSION="0.1"

#Download the file prerequisites
apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    iputils-ping \
    trickle \
    cron

###################################
#START: Docker Setup
###################################

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ${USER}

###################################
#END: Docker Setup
###################################


###################################
#START: Ground Station OS Setup
###################################
mkdir -p ${GROUND_STATION_DIR}
mkdir -p ${LOG_DIR}
mkdir -p ${SPACE_STATION_DIR}
mkdir -p /home/${USER}/.ssh

#Check if we have ssh keys already genned.  If not, create them
if [[ ! -f "${STATION_SSH_KEY}" ]]; then
    echo "Generating development SSH keys..."
    ssh-keygen -t rsa -b 4096 -f $STATION_SSH_KEY  -q -N ""    
    echo "Done"
fi
###################################
#END: Ground Station OS Setup
###################################


###################################
#START: Ground Station Docker Setup
###################################

#Check if the private Space Station vnet exists and if not, create it
APPNETWORK=$(docker network ls --format '{{.Name}}' | grep "${SPACE_NETWORK_NAME}")
if [ -z "${APPNETWORK}" ]; then
    echo "Creating private docker network '${SPACE_NETWORK_NAME}'..."
    docker network create --driver bridge --internal "${SPACE_NETWORK_NAME}"
    echo "Network created"
else
    echo "Private docker network '${SPACE_NETWORK_NAME}' exists"
fi




###################################
#END: Ground Station Docker Setup
###################################


###################################
#START: Finalize
###################################

echo "Mock Space Station Configuration (v $VERSION).  Provisioning Date: $(date)" >> /home/${USER}/Mock-SpaceStation-AzureVmSetup.txt

###################################
#END: Finalize
###################################
