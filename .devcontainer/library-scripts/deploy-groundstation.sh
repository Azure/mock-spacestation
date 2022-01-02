#!/bin/bash
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Syntax: ./deploy-groundstation.sh

set -e

error_log() {
	echo "deploy-groundstation.sh ERROR: ${1}" 1>&2
}

info_log() {
	echo "deploy-groundstation.sh ERROR: ${1}" 1>&2
}

# get supporting scripts

repository_uri="https://raw.githubusercontent.com/Azure/mock-spacestation"
branch_name="main"
container_dir=".devcontainer"
script_dir="library-scripts"

docker_in_docker_filename="docker-in-docker.sh"
docker_from_docker_filename="docker-debian.sh"
docker_groundstation_filename="Dockerfile.Groundstation"

docker_in_docker_script_uri="${repository_uri}/${branch_name}/${container_dir}/${script_dir}/${docker_in_docker_filename}"
docker_from_docker_script_uri="${repository_uri}/${branch_name}/${container_dir}/${script_dir}/${docker_from_docker_filename}"
spacestation_docker_file_uri="${repository_uri}/${branch_name}/${container_dir}/${docker_groundstation_filename}"

# set paths

# set container names

# configure directories

export GROUNDSTATION_ROOTDIR="/groundstation"
export GROUNDSTATION_USER=""
export GROUNDSTATION_LOGS="${GROUNDSTATION_ROOTDIR}/logs"
export GROUNDSTATION_OUTBOX="${GROUNDSTATION_ROOTDIR}/toSpaceStation"
export GROUNDSTATION_INBOX="${GROUNDSTATION_ROOTDIR}/fromSpaceStation"
export GROUNDSTATION_DinD="/usr/local/bin/docker-in-docker"
export GROUNDSTATION_DinD_CONTENTSBASE64="microsoft/vscode-dev-containers/containers/docker-in-docker.sh"
export SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="microsoft/vscode-dev-containers/containers/docker-from-docker.sh"
export SPACESTATION_DOCKERFILECONTENTS_BASE64="azure/mock-spacestation/Dockerfile.Spacestation"
export GROUNDSTATION_SSHKEY="${HOME}/.ssh/id_rsa_spaceStation"
export PROVISIONING_LOG="${GROUNDSTATION_LOGS}/deploy-groundstation.log"
export SPACESTATION_NETWORK_NAME="spaceDevVNet"
export SPACESTATION_CONTAINER_NAME="mockspacestation"
export GROUNDSTATION_VERSION="2.1"

GROUNDSTATION_USER=$(whoami)

# ********************************************************
# Miscellaneous Directories: START
# ********************************************************

sudo mkdir -p "$GROUNDSTATION_LOGS"
sudo mkdir -p "$GROUNDSTATION_OUTBOX"
sudo mkdir -p "$GROUNDSTATION_INBOX"
sudo mkdir -p "$HOME"/.ssh
sudo mkdir -p "$GROUNDSTATION_ROOTDIR"
sudo chown -R "$GROUNDSTATION_USER" "$GROUNDSTATION_ROOTDIR"

# ********************************************************
# Miscellaneous Directories: END
# ********************************************************

# ********************************************************
# Persistant Variables: START
# ********************************************************

sudo bash -c 'cat >> /etc/bash.bashrc' <<EOF
export GROUNDSTATION_LOGS="${GROUNDSTATION_ROOTDIR}"
export GROUNDSTATION_OUTBOX="${GROUNDSTATION_OUTBOX}"
export GROUNDSTATION_INBOX="${GROUNDSTATION_INBOX}"
export GROUNDSTATION_DinD="${GROUNDSTATION_DinD}"
export GROUNDSTATION_DinD_CONTENTSBASE64="${GROUNDSTATION_DinD_CONTENTSBASE64}"
export GROUNDSTATION_SSHKEY="${GROUNDSTATION_SSHKEY}"
export PROVISIONING_LOG="${PROVISIONING_LOG}"
export SPACESTATION_NETWORK_NAME="${SPACESTATION_NETWORK_NAME}"
export SPACESTATION_CONTAINER_NAME="${SPACESTATION_CONTAINER_NAME}"
export GROUNDSTATION_ROOTDIR="${GROUNDSTATION_ROOTDIR}"
export GROUNDSTATION_USER="${GROUNDSTATION_USER}"
export GROUNDSTATION_DinD_CONTENTSBASE64="${GROUNDSTATION_DinD_CONTENTSBASE64}"
export SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="${SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64}"
echo ""
echo ""
echo ""
echo ""
figlet Azure Mock SpaceStation
echo ""
echo ""
echo "Welcome to the Mock SpaceStation Template (https://github.com/azure/mock-spacestation) v2.1!"
echo ""
echo "This environment emulates the configuration and networking constraints observed by the Microsoft Azure Space Team while developing their genomics experiment to run on the International Space Station"
echo ""
echo "You are connected to the GroundStation"
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!" 

EOF

# ********************************************************
# Persistant Variables: END
# ********************************************************

if [[ $(whoami) -ne $GROUNDSTATION_USER ]]; then
	echo "Please rerun this script as user '$GROUNDSTATION_USER'."
	exit 1
fi

writeToProvisioningLog() {
	echo "$(date +%Y-%m-%d-%H%M%S): $1"
	echo "$(date +%Y-%m-%d-%H%M%S): $1" >>"$PROVISIONING_LOG"
}

# ********************************************************
# Setup Docker: START
# ********************************************************

sudo touch "$PROVISIONING_LOG"
sudo chown "$GROUNDSTATION_USER" "$PROVISIONING_LOG"
sudo chmod 777 "$PROVISIONING_LOG"
writeToProvisioningLog "Starting Mock SpaceStation Configuration (v $GROUNDSTATION_VERSION)"
writeToProvisioningLog "-----------------------------------------------------------"
writeToProvisioningLog "Working Dir: ${PWD}"
writeToProvisioningLog "Installing libraries"
writeToProvisioningLog "Deploy Docker in GroundStation (START)"

sudo apt-get update && export DEBIAN_FRONTEND=noninteractive &&
	sudo apt-get -y install --no-install-recommends \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg \
		lsb-release \
		flock \
		cron \
		trickle \
		libpam-cgfs \
		acl \
		figlet

writeToProvisioningLog "Installing regular Docker"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

sudo echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update &&
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io

ISREMOTECONTAINER=$(printenv | grep "REMOTE_CONTAINER")

if [ -n "${ISREMOTECONTAINER}" ]; then
	writeToProvisioningLog "...Enabling Docker in Docker"

	writeToProvisioningLog "...Writing Docker-in-Docker wrapper file to '$GROUNDSTATION_DinD'..."
	# Decode the DinD wrapper file embedded in the variable and write to the real file.
	# This keeps us needing only one uber file
	# base64 -w0 filename
	echo $GROUNDSTATION_DinD_CONTENTSBASE64 | base64 --decode | sudo tee $GROUNDSTATION_DinD >/dev/null
	sudo chmod +x "$GROUNDSTATION_DinD"

	sudo bash $GROUNDSTATION_DinD
fi
sudo usermod -aG docker "$GROUNDSTATION_USER"
sudo setfacl -m user:"$GROUNDSTATION_USER":rw /var/run/docker.sock

writeToProvisioningLog "Docker installed"

# ********************************************************
# Setup Docker: END
# ********************************************************

# ********************************************************
# Generate SSH Keys: START
# ********************************************************

writeToProvisioningLog "SSH Key Generation in GroundStation (START)"
sudo chmod 0700 "$HOME"/.ssh
ssh-keygen -t rsa -b 4096 -q -N '' -f "$GROUNDSTATION_SSHKEY"
sudo chmod 600 "$GROUNDSTATION_SSHKEY" &&
	sudo chmod 600 "$GROUNDSTATION_SSHKEY".pub &&
	cat "${GROUNDSTATION_SSHKEY}".pub >>/home/"${GROUNDSTATION_USER}"/.ssh/authorized_keys &&
	writeToProvisioningLog "SSH Key Generation in GroundStation (COMPLETE)"

# ********************************************************
# Generate SSH Keys: END
# ********************************************************

# ********************************************************
# Configure Docker: START
# ********************************************************

writeToProvisioningLog "Docker Config (START)"

APPNETWORK=$(sudo docker network ls --format '{{.Name}}' | grep "${SPACESTATION_NETWORK_NAME}")
if [ -z "${APPNETWORK}" ]; then
	writeToProvisioningLog "Creating docker network '$SPACESTATION_NETWORK_NAME'..."
	sudo docker network create --driver bridge --internal "$SPACESTATION_NETWORK_NAME"
	writeToProvisioningLog "Docker network '$SPACESTATION_NETWORK_NAME' created"
else
	writeToProvisioningLog "Docker network '$SPACESTATION_NETWORK_NAME' already exists"
fi

writeToProvisioningLog "Docker Config (COMPLETE)"

# ********************************************************
# Configure Docker: END
# ********************************************************

# ********************************************************
# Deploy SpaceStation Container: START
# ********************************************************
# docker container rm mockspacestation -f
# docker image rm mockspacestation-img
# docker container attach mockspacestation
# base64 -w0 ./.devcontainer/setupScripts/Dockerfile.Spacestation > output.txt

writeToProvisioningLog "Building Space Station Image '$SPACESTATION_CONTAINER_NAME-img'..."
echo $SPACESTATION_DOCKERFILECONTENTS_BASE64 | base64 --decode | sudo tee /tmp/Dockerfile.Spacestation >/dev/null
sudo chown "$GROUNDSTATION_USER" /tmp/Dockerfile.Spacestation
sudo chmod 1777 /tmp/Dockerfile.Spacestation

sudo docker build -t "$SPACESTATION_CONTAINER_NAME-img" --no-cache --build-arg SPACESTATION_USER="$GROUNDSTATION_USER" --build-arg PRIV_KEY="$(cat $GROUNDSTATION_SSHKEY)" --build-arg PUB_KEY="$(cat $GROUNDSTATION_SSHKEY.pub)" --build-arg SPACESTATION_DOCKERWRAPPERCONTENTS_BASE64="$GROUNDSTATION_DinD_CONTENTSBASE64" --file /tmp/Dockerfile.Spacestation .
writeToProvisioningLog "Space Station Image '$SPACESTATION_CONTAINER_NAME-img' successfully built"

writeToProvisioningLog "Starting Space Station Container '$SPACESTATION_CONTAINER_NAME'..."
sudo docker run -dit --privileged --hostname "$SPACESTATION_CONTAINER_NAME" --name "$SPACESTATION_CONTAINER_NAME" --network "$SPACESTATION_NETWORK_NAME" "$SPACESTATION_CONTAINER_NAME-img"

sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "/usr/local/bin/docker-wrapper"
sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "setfacl -m user:$GROUNDSTATION_USER:rw /var/run/docker.sock"
writeToProvisioningLog "'$SPACESTATION_CONTAINER_NAME' started..."

# ********************************************************
# Deploy SpaceStation Container: END
# ********************************************************

# ********************************************************
# Build SSH and RSYNC Jobs: START
# ********************************************************

sudo apt-get -y install --no-install-recommends trickle cron

writeToProvisioningLog "Building SSH connection to '$SPACESTATION_CONTAINER_NAME'..."
{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$GROUNDSTATION_SSHKEY" "$GROUNDSTATION_USER"@"$mockSpaceStationIP"'
} >${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

sudo chmod +x ${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

writeToProvisioningLog "Building sync job to '$SPACESTATION_CONTAINER_NAME' (${GROUNDSTATION_ROOTDIR}/sync-to-spacestation.sh)..."
{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo "GROUNDSTATION_SSHKEY=$GROUNDSTATION_SSHKEY"
	echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
	echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
	echo "Starting push to SpaceStation..."
	echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
	echo "Starting pull from SpaceStation..."
	echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'
} >/tmp/sync-to-spacestation.sh

sudo chmod +x /tmp/sync-to-spacestation.sh
sudo chmod 1777 /tmp/sync-to-spacestation.sh

{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo "GROUNDSTATION_SSHKEY=$GROUNDSTATION_SSHKEY"
	echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
	echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
	echo "Starting push to SpaceStation..."
	echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
	echo "Starting pull from SpaceStation..."
	echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'
} >/tmp/sync-to-spacestation-noThrottle.sh

sudo chmod +x /tmp/sync-to-spacestation-noThrottle.sh
sudo chmod 1777 /tmp/sync-to-spacestation-noThrottle.sh

echo "* * * * * /usr/bin/flock -w 0 /tmp/sync-to-spacestation-job.lock /tmp/sync-to-spacestation.sh >> $GROUNDSTATION_LOGS/sync-to-spacestation.log 2>&1" >/tmp/sync-to-spacestation-job
crontab /tmp/sync-to-spacestation-job
sudo service cron start

writeToProvisioningLog "-----------------------------------------------------------"
writeToProvisioningLog "Mock SpaceStation Configuration (v $GROUNDSTATION_VERSION) Complete.  Happy Space Deving!"

# ********************************************************
# Build SSH and RSYNC Jobs: END
# ********************************************************

sudo apt-get install -y figlet

clear

figlet Azure Mock SpaceStation

echo ""
echo ""
echo "Welcome to the Mock SpaceStation Template (https://github.com/azure/mock-spacestation) v2.1!"
echo ""
echo "This environment emulates the configuration and networking constraints observed by the Microsoft Azure Space Team while developing their genomics experiment to run on the International Space Station"
echo ""
echo "You are connected to the GroundStation"
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!"
cd "$GROUNDSTATION_ROOTDIR" || exit
