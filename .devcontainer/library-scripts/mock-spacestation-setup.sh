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
docker build -t $STATION_CONTAINER_NAME-img --no-cache --build-arg PRIV_KEY="$(cat $STATION_SSH_KEY)" --build-arg PUB_KEY="$(cat $STATION_SSH_KEY.pub)" --file /tmp/library-scripts/Dockerfile.SpaceStation .

echo "Starting '${STATION_CONTAINER_NAME}' container..."
docker run -dit  --name $STATION_CONTAINER_NAME --network $SPACE_NETWORK_NAME $STATION_CONTAINER_NAME-img

if [[ ! -f "/tmp/spacestation-sync.sh" ]]; then
    echo "Building spacestation-sync"    
    #Register cron

cat > "/tmp/spacestation-sync.sh" << EOF
#!/bin/bash
sudo rsync -arvz --bwlimit=250 -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $GROUND_STATION_DIR/* $STATION_USERNAME@$STATION_CONTAINER_NAME:~/groundstation
sudo rsync -arvz --bwlimit=250 -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $STATION_USERNAME@$STATION_CONTAINER_NAME:~/groundstation/* $GROUND_STATION_DIR
EOF

    echo "Done"
fi

chmod +x /tmp/spacestation-sync.sh


if [[ ! -f "/tmp/spaceStationSyncJob" ]]; then
    echo "Building rsync cron job"    
    #Register cron
    echo "* * * * * /tmp/spacestation-sync.sh >> $LOG_DIR/spacestation-sync.log 2>&1" >> /tmp/spaceStationSyncJob
    crontab /tmp/spaceStationSyncJob
    sudo service cron start
    #crontab -l
    #crontab -r #remove cron jobs
    echo "Done"
fi
