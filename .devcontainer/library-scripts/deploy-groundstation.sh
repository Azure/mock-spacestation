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
	echo "deploy-groundstation.sh INFO: ${1}" 1>&2
}

# get supporting scripts

repository_uri="https://raw.githubusercontent.com/Azure/mock-spacestation"
branch_name="glenn/jan2022updates"
script_dir=".devcontainer/library-scripts"

docker_in_docker_filename="docker-in-docker.sh"
docker_from_docker_filename="docker-debian.sh"
docker_spacestation_filename="Dockerfile.Spacestation"

docker_in_docker_script_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_in_docker_filename}"
docker_from_docker_script_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_from_docker_filename}"
spacestation_docker_file_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_spacestation_filename}"

# set globals

GROUNDSTATION_USER=$(whoami)
export GROUNDSTATION_USER
export GROUNDSTATION_VERSION="2.1"
export GROUNDSTATION_ROOTDIR="/groundstation"
export GROUNDSTATION_LOGS_DIR="${GROUNDSTATION_ROOTDIR}/logs"
export GROUNDSTATION_OUTBOX_DIR="${GROUNDSTATION_ROOTDIR}/toSpaceStation"
export GROUNDSTATION_INBOX_DIR="${GROUNDSTATION_ROOTDIR}/fromSpaceStation"
export GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH="/usr/local/bin/docker-in-docker"
export GROUNDSTATION_SSHKEY_FILEPATH="${HOME}/.ssh/id_rsa_spacestation"

export SPACESTATION_NETWORK_NAME="spaceDevVNet"
export SPACESTATION_DOCKERFILE_PATH="/tmp/Dockerfile.Spacestation"
export SPACESTATION_CONTAINER_NAME="mockspacestation"
export SPACESTATION_IMAGE_NAME="${SPACESTATION_CONTAINER_NAME}-img"
export SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH="/usr/local/bin/docker-from-docker"

export PROVISIONING_LOG="${GROUNDSTATION_LOGS_DIR}/deploy-groundstation.log"

# check user

if [[ $(whoami) -ne $GROUNDSTATION_USER ]]; then
	echo "Please rerun this script as user '$GROUNDSTATION_USER'."
	exit 1
fi

# setup logging

writeToProvisioningLog() {
	echo "$(date +%Y-%m-%d-%H%M%S): $1"
	echo "$(date +%Y-%m-%d-%H%M%S): $1" >>"$PROVISIONING_LOG"
}

# download scripts

info_log "Getting ${docker_in_docker_script_uri}..."
GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_CONTENTS=$(curl -s ${docker_in_docker_script_uri} | base64)
export GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_CONTENTS

info_log "Getting ${docker_from_docker_script_uri}..."
SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_CONTENTS=$(curl -s ${docker_from_docker_script_uri} | base64)
export SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_CONTENTS

info_log "Getting ${spacestation_docker_file_uri}..."
SPACESTATION_DOCKERFILE_CONTENTS=$(curl -s ${spacestation_docker_file_uri} | base64)
export SPACESTATION_DOCKERFILE_CONTENTS

# ********************************************************
# Miscellaneous Directories: START
# ********************************************************

sudo mkdir -p "$GROUNDSTATION_LOGS_DIR"
sudo mkdir -p "$GROUNDSTATION_OUTBOX_DIR"
sudo mkdir -p "$GROUNDSTATION_INBOX_DIR"
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
export GROUNDSTATION_USER=""
export GROUNDSTATION_VERSION="2.1"
export GROUNDSTATION_ROOTDIR="/groundstation"
export GROUNDSTATION_LOGS_DIR="${GROUNDSTATION_ROOTDIR}/logs"
export GROUNDSTATION_OUTBOX_DIR="${GROUNDSTATION_ROOTDIR}/toSpaceStation"
export GROUNDSTATION_INBOX_DIR="${GROUNDSTATION_ROOTDIR}/fromSpaceStation"
export GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH="/usr/local/bin/docker-in-docker"
export GROUNDSTATION_SSHKEY_FILEPATH="${HOME}/.ssh/id_rsa_spacestation"
export GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_CONTENTS
export SPACESTATION_NETWORK_NAME="spaceDevVNet"
export SPACESTATION_CONTAINER_NAME="mockspacestation"
export SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_CONTENTS
export SPACESTATION_DOCKERFILE_CONTENTS
export PROVISIONING_LOG="${GROUNDSTATION_LOGS_DIR}/deploy-groundstation.log"
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
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX_DIR' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX_DIR' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!" 

EOF

# ********************************************************
# Persistant Variables: END
# ********************************************************

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
writeToProvisioningLog "updating packages"

sudo apt-get update
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y install --no-install-recommends \
	util-linux \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	cron \
	trickle \
	libpam-cgfs \
	acl \
	figlet

writeToProvisioningLog "updated packages"

# check for docker

writeToProvisioningLog "check for docker"

if ! command -v docker &> /dev/null; then

	writeToProvisioningLog "installing Docker..."
	
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

	sudo echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

	sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io

	writeToProvisioningLog "Docker installed!"

fi

writeToProvisioningLog "check if remote container"

if printenv | grep -q "REMOTE_CONTAINER"; then

	writeToProvisioningLog "This is a Remote Container, enabling Docker in Docker..."

	writeToProvisioningLog "Downloading Docker-in-Docker script from '${docker_in_docker_script_uri}' to '$GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH'..."
	curl -s "${docker_in_docker_script_uri}" -o "${GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH}"

	writeToProvisioningLog "Executing Docker-in-Docker script at '$GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH'..."
	. "$GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH"

	writeToProvisioningLog "Docker in Docker Enabled for Remote Container!"

fi

writeToProvisioningLog "add user to docker group"

sudo usermod -aG docker "$GROUNDSTATION_USER"

writeToProvisioningLog "set docker acl for user"

sudo setfacl -m user:"$GROUNDSTATION_USER":rw /var/run/docker.sock

# ********************************************************
# Setup Docker: END
# ********************************************************

# ********************************************************
# Generate SSH Keys: START
# ********************************************************

writeToProvisioningLog "SSH Key Generation in GroundStation (START)"
sudo chmod 0700 "$HOME"/.ssh
ssh-keygen -t rsa -b 4096 -q -N '' -f "$GROUNDSTATION_SSHKEY_FILEPATH"
sudo chmod 600 "$GROUNDSTATION_SSHKEY_FILEPATH" &&
	sudo chmod 600 "$GROUNDSTATION_SSHKEY_FILEPATH".pub &&
	cat "${GROUNDSTATION_SSHKEY_FILEPATH}".pub >>/home/"${GROUNDSTATION_USER}"/.ssh/authorized_keys &&
	writeToProvisioningLog "SSH Key Generation in GroundStation (COMPLETE)"

# ********************************************************
# Generate SSH Keys: END
# ********************************************************

# ********************************************************
# Configure Docker: START
# ********************************************************

writeToProvisioningLog "setting up docker networking"

if ! sudo docker network ls --format '{{.Name}}' | grep -q "${SPACESTATION_NETWORK_NAME}"; then
	writeToProvisioningLog "creating docker network '$SPACESTATION_NETWORK_NAME'..."
	sudo docker network create --driver bridge --internal "$SPACESTATION_NETWORK_NAME"
	writeToProvisioningLog "docker network '$SPACESTATION_NETWORK_NAME' created"
fi

writeToProvisioningLog "docker networking setup complete"

# ********************************************************
# Configure Docker: END
# ********************************************************

# ********************************************************
# Deploy SpaceStation Container: START
# ********************************************************

writeToProvisioningLog "building spacestation image '${SPACESTATION_IMAGE_NAME}'..."

writeToProvisioningLog "write spacestation Dockerfile into '${SPACESTATION_DOCKERFILE_PATH}' from '${spacestation_docker_file_uri}'..."
curl -s "${spacestation_docker_file_uri}" -o "${SPACESTATION_DOCKERFILE_PATH}"

writeToProvisioningLog "change Dockerfile at '${SPACESTATION_DOCKERFILE_PATH}' ownership to user '${GROUNDSTATION_USER}'"
sudo chown "$GROUNDSTATION_USER" "${SPACESTATION_DOCKERFILE_PATH}"
sudo chmod 1777 "${SPACESTATION_DOCKERFILE_PATH}"

writeToProvisioningLog "build image '${SPACESTATION_IMAGE_NAME}' from '${SPACESTATION_DOCKERFILE_PATH}'"
sudo docker build -t "${SPACESTATION_IMAGE_NAME}" \
	--no-cache \
	--build-arg SPACESTATION_USER="$GROUNDSTATION_USER" \
	--build-arg PRIV_KEY="$(cat "${GROUNDSTATION_SSHKEY_FILEPATH}")" \
	--build-arg PUB_KEY="$(cat "${GROUNDSTATION_SSHKEY_FILEPATH}".pub)" \
	--build-arg DOCKER_FROM_DOCKER_SCRIPT_URI="${docker_from_docker_script_uri}" \
	--build-arg DOCKER_FROM_DOCKER_SCRIPT_PATH="${SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH}" \
	--file "${SPACESTATION_DOCKERFILE_PATH}" .

writeToProvisioningLog "spacestation image '${SPACESTATION_IMAGE_NAME}' built!"

writeToProvisioningLog "starting spacestation container '$SPACESTATION_CONTAINER_NAME'..."

writeToProvisioningLog "run image '${SPACESTATION_IMAGE_NAME}'"
sudo docker run -dit \
	--privileged \
	--hostname "$SPACESTATION_CONTAINER_NAME" \
	--name "$SPACESTATION_CONTAINER_NAME" \
	--network "$SPACESTATION_NETWORK_NAME" \
	"${SPACESTATION_IMAGE_NAME}"

writeToProvisioningLog "execute docker-wrapper script at '${SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH}' on '${SPACESTATION_CONTAINER_NAME}'"
sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "${SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH}"

writeToProvisioningLog "set docker acl on '${SPACESTATION_CONTAINER_NAME}' for user '${GROUNDSTATION_USER}'"
sudo docker exec -ti "$SPACESTATION_CONTAINER_NAME" bash -c "setfacl -m user:$GROUNDSTATION_USER:rw /var/run/docker.sock"

writeToProvisioningLog "'$SPACESTATION_CONTAINER_NAME' started!"

# ********************************************************
# Deploy SpaceStation Container: END
# ********************************************************

# ********************************************************
# Build SSH and RSYNC Jobs: START
# ********************************************************

writeToProvisioningLog "Building SSH connection to '$SPACESTATION_CONTAINER_NAME'..."
{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$GROUNDSTATION_SSHKEY_FILEPATH" "$GROUNDSTATION_USER"@"$mockSpaceStationIP"'
} >${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

sudo chmod +x ${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh

writeToProvisioningLog "Building sync job to '$SPACESTATION_CONTAINER_NAME' (${GROUNDSTATION_ROOTDIR}/sync-to-spacestation.sh)..."
{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo "GROUNDSTATION_SSHKEY_FILEPATH=$GROUNDSTATION_SSHKEY_FILEPATH"
	echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
	echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
	echo "Starting push to SpaceStation..."
	echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY_FILEPATH" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
	echo "Starting pull from SpaceStation..."
	echo 'rsync --rsh="trickle -d 250KiB -u 250KiB  -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY_FILEPATH" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'
} >/tmp/sync-to-spacestation.sh

sudo chmod +x /tmp/sync-to-spacestation.sh
sudo chmod 1777 /tmp/sync-to-spacestation.sh

{
	echo '#!/bin/bash'
	echo 'mockSpaceStationIP=$(sudo docker inspect mockspacestation --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")'
	echo "GROUNDSTATION_SSHKEY_FILEPATH=$GROUNDSTATION_SSHKEY_FILEPATH"
	echo "GROUNDSTATION_ROOTDIR=$GROUNDSTATION_ROOTDIR"
	echo "GROUNDSTATION_USER=$GROUNDSTATION_USER"
	echo "Starting push to SpaceStation..."
	echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY_FILEPATH" --remove-source-files --verbose --progress $GROUNDSTATION_ROOTDIR/toSpaceStation/* $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/fromGroundStation/'
	echo "Starting pull from SpaceStation..."
	echo 'rsync --rsh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $GROUNDSTATION_SSHKEY_FILEPATH" --remove-source-files --verbose --progress $GROUNDSTATION_USER@$mockSpaceStationIP:/home/$GROUNDSTATION_USER/toGroundStation/* $GROUNDSTATION_ROOTDIR/fromSpaceStation/'
} >/tmp/sync-to-spacestation-noThrottle.sh

sudo chmod +x /tmp/sync-to-spacestation-noThrottle.sh
sudo chmod 1777 /tmp/sync-to-spacestation-noThrottle.sh

echo "* * * * * /usr/bin/flock -w 0 /tmp/sync-to-spacestation-job.lock /tmp/sync-to-spacestation.sh >> $GROUNDSTATION_LOGS_DIR/sync-to-spacestation.log 2>&1" >/tmp/sync-to-spacestation-job
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
echo "     To send a file to the SpaceStation, place it in the '$GROUNDSTATION_OUTBOX_DIR' directory"
echo "     Files received from the SpaceStation will be in the '$GROUNDSTATION_INBOX_DIR' directory"
echo "To SSH to SpaceStation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     Files received from the GroundStation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     To send a file to the GroundStation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo "Happy Space Deving!"
cd "$GROUNDSTATION_ROOTDIR" || exit
