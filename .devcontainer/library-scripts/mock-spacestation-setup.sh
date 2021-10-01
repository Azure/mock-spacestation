#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Sets up the local dev container to emulate connectivity to the Space Station
#
# Syntax: ./mock-spacestation-setup.sh

#Check if the private Space Station vnet exists and if not, create it
SPACESTATION_FILE="/tmp/library-scripts/Dockerfile.SpaceStation"

mkdir -p $GROUND_STATION_DIR
mkdir -p $SPACE_STATION_DIR
mkdir -p $LOG_DIR

APPNETWORK=$(docker network ls --format '{{.Name}}' | grep "${SPACE_NETWORK_NAME}")

if [ -z "${APPNETWORK}" ]; then
    echo "Creating private docker network '${SPACE_NETWORK_NAME}'..."
    docker network create --driver bridge --internal "${SPACE_NETWORK_NAME}"
    echo "Network created"
else
    echo "Private docker network '${SPACE_NETWORK_NAME}' exists"
fi

#Check the dev container is attached to the dev vnet
HAS_NETWORK=$(docker network inspect ${SPACE_NETWORK_NAME} --format '{{json .Containers}}' | grep $HOSTNAME)
if [ -z "${HAS_NETWORK}" ]; then
    echo "Attaching Dev to container '${SPACE_NETWORK_NAME}'..."
    docker network connect $SPACE_NETWORK_NAME $HOSTNAME
fi

#Check if the mock-station container is loaded but not running
HAS_STATION_CONTAINER=$(docker container ls -a --format '{{ .Names }}--{{ .State }}' | grep $STATION_CONTAINER_NAME)
if [[ ! -z "${HAS_STATION_CONTAINER}" ]]; then
    echo "Dropping old '${STATION_CONTAINER_NAME}' container..."
    docker container rm $STATION_CONTAINER_NAME -f
fi


#Check if we have ssh keys already genned.  If not, create them
if [[ ! -f "${STATION_SSH_KEY}" ]]; then
    echo "Generating development SSH keys..."
    ssh-keygen -t rsa -b 4096 -f $STATION_SSH_KEY  -q -N ""
    echo "Done"
fi

echo "Building '${STATION_CONTAINER_NAME}' image..."
#SPACESTATION_FILE="./.devcontainer/library-scripts/Dockerfile.SpaceStation"
docker build -t $STATION_CONTAINER_NAME-img --no-cache --build-arg PRIV_KEY="$(cat $STATION_SSH_KEY)" --build-arg PUB_KEY="$(cat $STATION_SSH_KEY.pub)" --file $SPACESTATION_FILE ./.devcontainer/library-scripts/

echo "Starting '${STATION_CONTAINER_NAME}' container..."
docker run -dit --privileged --hostname $STATION_CONTAINER_NAME --name $STATION_CONTAINER_NAME --network $SPACE_NETWORK_NAME $STATION_CONTAINER_NAME-img

if [[ ! -f "/tmp/spacestation-sync.sh" ]]; then
    echo "Building spacestation-sync"
    #Register cron

#Build the sync script to do 2 1-way RSYNC (Push, then pull).  Use trickle to keep bandwidth @ 250KB/s
cat > "/tmp/spacestation-sync.sh" << EOF
#!/bin/bash
if [ -e "/tmp/spacestation-sync.running" ]; then
    echo "Sync is already running.  No work to do"
   exit
else
   touch "/tmp/spacestation-sync.running"
   echo "Starting Sync"
   rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $GROUND_STATION_DIR/* $STATION_USERNAME@$STATION_CONTAINER_NAME:~/groundstation
   rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $STATION_USERNAME@$STATION_CONTAINER_NAME:~/spacestation/* $SPACE_STATION_DIR/
   rm "/tmp/spacestation-sync.running"
fi

EOF
    echo "Done"
fi


if [[ ! -f "/tmp/spacestation-sync-nothrottle.sh" ]]; then
    echo "Building spacestation-nothrottle"
    #Register cron

#Build the cheater sync script to do 2 1-way RSYNC (Push, then pull).  No bandwidth limitations
cat > "/tmp/spacestation-sync-nothrottle.sh" << EOF
#!/bin/bash
echo "This is used to synchronize without the bandwidth throttle.  It does NOT accurately represent the production experience.  Use with caution - it's cheating"
docker cp $GROUND_STATION_DIR/. $STATION_CONTAINER_NAME:/home/azureuser/groundstation/
docker cp $STATION_CONTAINER_NAME:/home/azureuser/spacestation/. $SPACE_STATION_DIR/
EOF
    echo "Done"
fi



#Update spacestation-sync with executable rights
chmod +x /tmp/spacestation-sync.sh
chmod +x /tmp/spacestation-sync-nothrottle.sh
chmod +x ./ssh-to-spacestation.sh
chmod 1777 $GROUND_STATION_DIR
chmod 1777 $SPACE_STATION_DIR
chmod 1777 $LOG_DIR
sudo chown vscode $GROUND_STATION_DIR
sudo chown vscode $SPACE_STATION_DIR
sudo chown vscode $LOG_DIR


if [[ ! -f "/tmp/spaceStationSyncJob" ]]; then
    echo "Building rsync cron job"
    #Register cron
    echo "* * * * * /tmp/spacestation-sync.sh >> $LOG_DIR/spacestation-sync.log 2>&1" > /tmp/spaceStationSyncJob
    crontab /tmp/spaceStationSyncJob
    sudo service cron start
    #crontab -l #list cron jobs
    #crontab -r #remove cron jobs
    echo "Done"
fi
