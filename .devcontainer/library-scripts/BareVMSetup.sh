#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Used on a blank VM Sets up the local environment to emulate connectivity to the SpaceStation.  This is slipstreamed into the AzureVM.bicep file to be ran when the VM is provisioned
# Syntax: ./BareVMSetup.sh


USER="azureuser"
SPACE_NETWORK_NAME="spacedev-vnet-spacestation"
STATION_SSH_KEY="/home/${USER}/.ssh/id_rsa_spaceStation"
STATION_CONTAINER_NAME="spacedev-spacestation"
STATION_DOCKER_FILE="/tmp/library-scripts/Dockerfile.SpaceStation"
GROUND_STATION_DIR="/home/${USER}/groundstation"
LOG_DIR="/home/${USER}/logs"
SPACE_STATION_DIR="/home/${USER}/spacestation"
VERSION="2.0"
LOGFILE="/home/${USER}/mockspacestation-provisioning.log"
GITHUB_SRC="https://raw.githubusercontent.com/azure/mock-spacestation/main"

echo "Starting Mock SpaceStation Configuration (v $VERSION)" > $LOGFILE
echo "-----------------------------------------------------------" >> $LOGFILE
echo "$(date): Working Dir: ${PWD}" >> $LOGFILE
echo "$(date): Installing libraries" >> $LOGFILE
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
echo "$(date): Docker Setup Start" >> $LOGFILE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker ${USER}
sudo setfacl -m user:${USER}:rw /var/run/docker.sock
echo "$(date): Docker Setup Complete" >> $LOGFILE
###################################
#END: Docker Setup
###################################


###################################
#START: Ground Station OS Setup
###################################
echo "$(date): Ground Station OS Setup Start" >> $LOGFILE
mkdir -p ${GROUND_STATION_DIR}
mkdir -p ${LOG_DIR}
mkdir -p ${SPACE_STATION_DIR}
mkdir -p /home/${USER}/.ssh
mkdir -p /tmp/library-scripts
chmod 1777 /tmp/library-scripts

#Check if we have ssh keys already genned.  If not, create them
if [[ ! -f "${STATION_SSH_KEY}" ]]; then
    echo "Generating development SSH keys..."
    ssh-keygen -t rsa -b 4096 -f $STATION_SSH_KEY  -q -N ""    
    echo "Done"
fi

chmod 600 ${STATION_SSH_KEY} && \
chmod 600 ${STATION_SSH_KEY}.pub && \
chmod 1777 /home/${USER}/groundstation && \
chmod 1777 /home/${USER}/spacestation && \
cat ${STATION_SSH_KEY}.pub >> /home/${USER}/.ssh/authorized_keys && \
chown ${USER} ${STATION_SSH_KEY} && \
chown ${USER} ${STATION_SSH_KEY}.pub && \
chown ${USER} /home/${USER}/.ssh/authorized_keys



echo "$(date): Ground Station OS Setup Complete" >> $LOGFILE
###################################
#END: Ground Station OS Setup
###################################


###################################
#START: Ground Station Docker Setup
###################################
echo "$(date): Docker configuration Start" >> $LOGFILE
#Check if the private Space Station vnet exists and if not, create it
APPNETWORK=$(docker network ls --format '{{.Name}}' | grep "${SPACE_NETWORK_NAME}")
if [ -z "${APPNETWORK}" ]; then
    echo "Creating private docker network '${SPACE_NETWORK_NAME}'..."
    docker network create --driver bridge --internal "${SPACE_NETWORK_NAME}"
    echo "Network created"
else
    echo "Private docker network '${SPACE_NETWORK_NAME}' exists"
fi


echo "$(date): Downloading Library Scripts Start" >> $LOGFILE
curl "${GITHUB_SRC}/.devcontainer/library-scripts/Dockerfile.SpaceStation" -o $STATION_DOCKER_FILE --silent
curl "${GITHUB_SRC}/.devcontainer/library-scripts/docker-in-docker.sh" -o /tmp/library-scripts/docker-in-docker.sh --silent
chmod 1777 /tmp/library-scripts/Dockerfile.SpaceStation_BareVM
chmod 1777 /tmp/library-scripts/docker-in-docker.sh
echo "$(date): Downloading Library Scripts Complete" >> $LOGFILE



echo "$(date): SpaceStation Container Build Start" >> $LOGFILE
docker build -t $STATION_CONTAINER_NAME-img --no-cache --build-arg PRIV_KEY="$(cat $STATION_SSH_KEY)" --build-arg PUB_KEY="$(cat $STATION_SSH_KEY.pub)" --file $STATION_DOCKER_FILE /tmp/library-scripts/
echo "$(date): SpaceStation Container Build Complete" >> $LOGFILE

echo "$(date): SpaceStation Container Start" >> $LOGFILE
docker run -dit --privileged --hostname "mockSpacestation" --name $STATION_CONTAINER_NAME --network $SPACE_NETWORK_NAME $STATION_CONTAINER_NAME-img
echo "$(date): SpaceStation Container Complete" >> $LOGFILE

if [[ ! -f "/tmp/spacestation-sync.sh" ]]; then
    echo "Building spacestation-sync"    
    #Register cron

#Build the sync script to do 2 1-way RSYNC (Push, then pull).  Use trickle to keep bandwidth @ 250KB/s
cat > "/tmp/spacestation-sync.sh" << EOF
#!/bin/bash
if [ -e "/tmp/sync-running" ]; then 
    echo "Sync is already running.  No work to do"
   exit
else   
   touch "/tmp/sync-running"
   chmod 1777 "/tmp/sync-running"   
   echo "Starting push from Ground Station to Space Station..."
   rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $GROUND_STATION_DIR/* $USER@172.18.0.2:~/groundstation  
   echo ""
   echo ""
   echo "Starting pull from Space Station to Ground Station"
   rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY" --verbose --progress $USER@172.18.0.2:~/spacestation/* $SPACE_STATION_DIR/  
   rm "/tmp/sync-running"
   echo "-------------------------------"
   echo ""
   echo ""
fi

EOF
    echo "Done"
fi

chmod 1777 /tmp/spacestation-sync.sh



if [[ ! -f "/tmp/spacestation-sync-nothrottle.sh" ]]; then
    echo "Building spacestation-nothrottle"    
    #Register cron

#Build the cheater sync script to do 2 1-way RSYNC (Push, then pull).  No bandwidth limitations
cat > "/tmp/spacestation-sync-nothrottle.sh" << EOF
#!/bin/bash
echo "This is used to synchronize without the bandwidth throttle.  It does NOT accurately represent the production experience.  Use with caution - it's cheating"
touchfile "/tmp/sync-running"
echo "Starting push from Ground to Space Station..."
docker cp $GROUND_STATION_DIR/. $STATION_CONTAINER_NAME:/home/azureuser/groundstation/
echo "Starting pull from Space Station to Ground..."
docker cp $STATION_CONTAINER_NAME:/home/azureuser/spacestation/. $SPACE_STATION_DIR/
rm "/tmp/sync-running"
echo "Done"
EOF
    echo "Done"
fi

chmod 1777 /tmp/spacestation-sync-nothrottle.sh



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



if [[ ! -f "/home/${USER}/ssh-to-spacestation.sh" ]]; then
    
#Build the sync script to do 2 1-way RSYNC (Push, then pull).  Use trickle to keep bandwidth @ 250KB/s
cat > "/home/${USER}/ssh-to-spacestation.sh" << EOF
    trickle -s -d 5 -u 5 -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY $USER@172.18.0.2
EOF
    echo "Done"
fi

chmod +x "/home/${USER}/ssh-to-spacestation.sh"

echo "$(date): Docker configuration End" >> $LOGFILE


###################################
#START: Finalize
###################################
echo "-----------------------------------------------------------" >> $LOGFILE
echo "$(date): Mock SpaceStation Configuration (v $VERSION) Complete." >> $LOGFILE

###################################
#END: Finalize
###################################
