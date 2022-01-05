#!/bin/bash
#
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Syntax: ./deploy-groundstation.sh

set -e

# set supporting scripts uris

repository_uri="https://raw.githubusercontent.com/Azure/mock-spacestation"
branch_name="glenn/jan2022updates"
script_dir=".devcontainer/library-scripts"

docker_in_docker_filename="docker-in-docker-debian.sh"
docker_from_docker_filename="docker-debian.sh"
docker_spacestation_filename="Dockerfile.Spacestation"

docker_in_docker_script_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_in_docker_filename}"
docker_from_docker_script_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_from_docker_filename}"
spacestation_docker_file_uri="${repository_uri}/${branch_name}/${script_dir}/${docker_spacestation_filename}"

# set vars

GROUNDSTATION_USER=$(whoami)
export GROUNDSTATION_USER
export GROUNDSTATION_VERSION="2.1"
export GROUNDSTATION_ROOTDIR="/groundstation"
export GROUNDSTATION_LOGS_DIR="${GROUNDSTATION_ROOTDIR}/logs"
export GROUNDSTATION_OUTBOX_DIR="${GROUNDSTATION_ROOTDIR}/toSpaceStation"
export GROUNDSTATION_INBOX_DIR="${GROUNDSTATION_ROOTDIR}/fromSpaceStation"
export GROUNDSTATION_DOCKER_IN_DOCKER_SCRIPT_FILEPATH="/tmp/docker-in-docker"
export GROUNDSTATION_SSHKEY_FILEPATH="${HOME}/.ssh/id_rsa_spacestation"
export GROUNDSTATION_SSH_SCRIPT_FILENAME="ssh-to-spacestation.sh"
export GROUNDSTATION_CRON_JOB_FILENAME="sync-to-spacestation.sh"
export GROUNDSTATION_CRON_JOB_UNTHROTTLED_FILENAME="sync-to-spacestation-unthrottled.sh"

export SPACESTATION_NETWORK_NAME="spaceDevVNet"
export SPACESTATION_DOCKERFILE_PATH="/tmp/Dockerfile.Spacestation"
export SPACESTATION_CONTAINER_NAME="mockspacestation"
export SPACESTATION_IMAGE_NAME="${SPACESTATION_CONTAINER_NAME}-img"
export SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH="/tmp/docker-from-docker"

export PROVISIONING_LOG="${GROUNDSTATION_LOGS_DIR}/deploy-groundstation.log"

# setup logging

writeToProvisioningLog() {
	echo "$(date +%Y-%m-%d-%H%M%S): $1"
	echo "$(date +%Y-%m-%d-%H%M%S): $1" >> "$PROVISIONING_LOG"
}

# make directories

sudo mkdir -p "$GROUNDSTATION_LOGS_DIR"
sudo mkdir -p "$GROUNDSTATION_OUTBOX_DIR"
sudo mkdir -p "$GROUNDSTATION_INBOX_DIR"
sudo mkdir -p "$GROUNDSTATION_ROOTDIR"
sudo chown -R "$GROUNDSTATION_USER" "$GROUNDSTATION_ROOTDIR"

sudo mkdir -p "$HOME"/.ssh

# start logging

sudo touch "$PROVISIONING_LOG"
sudo chown "$GROUNDSTATION_USER" "$PROVISIONING_LOG"
sudo chmod 777 "$PROVISIONING_LOG"
writeToProvisioningLog "Starting Mock SpaceStation Configuration (v $GROUNDSTATION_VERSION)"
writeToProvisioningLog "-----------------------------------------------------------"
writeToProvisioningLog "Working Dir: ${PWD}"

# update host packages

writeToProvisioningLog "PACKAGES: updating..."

sudo apt-get update >>/dev/null && # TODO (20220103 gmusa): replace with debug file logging
export DEBIAN_FRONTEND=noninteractive &&
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
	figlet \
	>>/dev/null # TODO (20220103 gmusa): replace with debug file logging

writeToProvisioningLog "PACKAGES: updated!"

# setup docker

set +e

writeToProvisioningLog "DOCKER: setting up..."

writeToProvisioningLog "check for docker..."
if type docker > /dev/null 2>&1; then
	writeToProvisioningLog "installing Docker..."
	
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	sudo echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io >> /dev/null # TODO (20220103 gmusa): replace with debug file logging

	writeToProvisioningLog "Docker installed!"
fi

writeToProvisioningLog "adding user '${GROUNDSTATION_USER}' to docker group..."
sudo usermod -aG docker "$GROUNDSTATION_USER"
writeToProvisioningLog "user '${GROUNDSTATION_USER}' added to docker group!"

writeToProvisioningLog "setting docker acl for '${GROUNDSTATION_USER}'..."
sudo setfacl -m user:"$GROUNDSTATION_USER":rw /var/run/docker.sock
writeToProvisioningLog "docker acl set for '${GROUNDSTATION_USER}!'"

writeToProvisioningLog "remove, if any, existing spacestation container '${SPACESTATION_CONTAINER_NAME}'..."
sudo docker ps -aq --filter "name=${SPACESTATION_CONTAINER_NAME}" | grep -q . \
	&& sudo docker rm -fv "${SPACESTATION_CONTAINER_NAME}" \
	&& sudo docker rmi --force "${SPACESTATION_IMAGE_NAME}"
writeToProvisioningLog "removed existing spacestation container!"

writeToProvisioningLog "remove, if any, existing network..."
sudo docker network ls -q --filter "name=${SPACESTATION_NETWORK_NAME}" | grep -q . \
	&& sudo docker network rm "${SPACESTATION_NETWORK_NAME}"

writeToProvisioningLog "create a network '${SPACESTATION_NETWORK_NAME}'..."
sudo docker network create \
	--driver bridge \
	"${SPACESTATION_NETWORK_NAME}"
writeToProvisioningLog "network '${SPACESTATION_NETWORK_NAME}' created"

writeToProvisioningLog "DOCKER: setup complete!"

set -e

# generate SSH keys

writeToProvisioningLog "SSH KEYS: generating groundstation keys..."

writeToProvisioningLog "writing a rsa key to '${GROUNDSTATION_SSHKEY_FILEPATH}'..."
sudo chmod 700 "$HOME"/.ssh
sudo ssh-keygen -t rsa -b 4096 -q -N '' -f "${GROUNDSTATION_SSHKEY_FILEPATH}"
writeToProvisioningLog "rsa key written to '${GROUNDSTATION_SSHKEY_FILEPATH}'!"

writeToProvisioningLog "adding rsa key at '${GROUNDSTATION_SSHKEY_FILEPATH}' to authorized_keys..."
sudo chmod 600 "${GROUNDSTATION_SSHKEY_FILEPATH}"
sudo chmod 600 "${GROUNDSTATION_SSHKEY_FILEPATH}".pub
sudo chmod 777 "$HOME"/.ssh
sudo cat "${GROUNDSTATION_SSHKEY_FILEPATH}.pub" | tee -a "/home/${GROUNDSTATION_USER}/.ssh/authorized_keys"
writeToProvisioningLog "rsa key added to authorized_keys!"

writeToProvisioningLog "SSH KEYS: groundstation keys generated!"

# build spacestation image

writeToProvisioningLog "BUILD IMAGE: builiding spacestation image '${SPACESTATION_IMAGE_NAME}'..."

writeToProvisioningLog "downloading spacestation Dockerfile into '${SPACESTATION_DOCKERFILE_PATH}' from '${spacestation_docker_file_uri}'..."
curl -s "${spacestation_docker_file_uri}" -o "${SPACESTATION_DOCKERFILE_PATH}"
writeToProvisioningLog "spacestation Dockerfile downloaded!"

writeToProvisioningLog "changing Dockerfile at '${SPACESTATION_DOCKERFILE_PATH}' ownership to user '${GROUNDSTATION_USER}'..."
sudo chown "$GROUNDSTATION_USER" "${SPACESTATION_DOCKERFILE_PATH}"
sudo chmod 777 "${SPACESTATION_DOCKERFILE_PATH}"
writeToProvisioningLog "Dockerfile ownership updated!"

writeToProvisioningLog "building image '${SPACESTATION_IMAGE_NAME}' from '${SPACESTATION_DOCKERFILE_PATH}'..."
sudo docker build -t "${SPACESTATION_IMAGE_NAME}" \
	--no-cache \
	--build-arg SPACESTATION_USER="$GROUNDSTATION_USER" \
	--build-arg PRIV_KEY="$(sudo cat "${GROUNDSTATION_SSHKEY_FILEPATH}")" \
	--build-arg PUB_KEY="$(sudo cat "${GROUNDSTATION_SSHKEY_FILEPATH}".pub)" \
	--build-arg DOCKER_FROM_DOCKER_SCRIPT_URI="${docker_from_docker_script_uri}" \
	--build-arg DOCKER_FROM_DOCKER_SCRIPT_FILEPATH="${SPACESTATION_DOCKER_FROM_DOCKER_SCRIPT_FILEPATH}" \
	--file "${SPACESTATION_DOCKERFILE_PATH}" . \
	>>/dev/null # TODO (20220103 gmusa): replace with debug file logging
sudo chmod 700 "$HOME"/.ssh
writeToProvisioningLog "image built!"

writeToProvisioningLog "BUILD IMAGE: spacestation image '${SPACESTATION_IMAGE_NAME}' built!"

# start container

writeToProvisioningLog "RUN CONTAINER: start spacestation container..."

writeToProvisioningLog "creating a container called '${SPACESTATION_CONTAINER_NAME}' based off image '${SPACESTATION_IMAGE_NAME}'..."
sudo docker run -dit \
	--privileged \
	--hostname "${SPACESTATION_CONTAINER_NAME}" \
	--name "${SPACESTATION_CONTAINER_NAME}" \
	--network "${SPACESTATION_NETWORK_NAME}" \
	"${SPACESTATION_IMAGE_NAME}"
writeToProvisioningLog "spacestation container running!"

writeToProvisioningLog "set docker acl on '${SPACESTATION_CONTAINER_NAME}' for user '${GROUNDSTATION_USER}'"
sudo docker exec -ti "${SPACESTATION_CONTAINER_NAME}" \
	bash -c "setfacl -m user:${GROUNDSTATION_USER}:rw /var/run/docker.sock"
writeToProvisioningLog "docker acl set!"

writeToProvisioningLog "recreating network '${SPACESTATION_NETWORK_NAME}' to remove internet access..."

writeToProvisioningLog "removing network from container '${SPACESTATION_CONTAINER_NAME}'..."
sudo docker network disconnect "${SPACESTATION_NETWORK_NAME}" "${SPACESTATION_CONTAINER_NAME}"
writeToProvisioningLog "network removed from container!"

writeToProvisioningLog "removing network with internet access..."
sudo docker network rm "${SPACESTATION_NETWORK_NAME}"
writeToProvisioningLog "network with internet access removed!"

writeToProvisioningLog "recreating network with internal access only..."
sudo docker network create \
	--driver bridge \
	--internal \
	"${SPACESTATION_NETWORK_NAME}"
writeToProvisioningLog "network recreated with internal traffic only!"

writeToProvisioningLog "reconnecting network to container '${SPACESTATION_CONTAINER_NAME}'..."
sudo docker network connect "${SPACESTATION_NETWORK_NAME}" "${SPACESTATION_CONTAINER_NAME}"
writeToProvisioningLog "network reconnected to container!"

writeToProvisioningLog "RUN CONTAINER: container started!"

# build SSH connection

writeToProvisioningLog "getting spacestation container IP address"
mockspacestation_ip=$(sudo docker inspect ${SPACESTATION_CONTAINER_NAME} --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}")
writeToProvisioningLog "spacestation container IP address '${mockspacestation_ip}' retrieved"

writeToProvisioningLog "updating spacestation known hosts for passwordless SSH to groundstation"
writeToProvisioningLog "hostname: $(hostname)"
writeToProvisioningLog "ip address: $(hostname -I)"
groundstation_hostname=$(hostname -I)
sudo docker exec -ti "${SPACESTATION_CONTAINER_NAME}" \
	bash -c "ssh-keyscan -p 2222 ${groundstation_hostname} >> /home/${GROUNDSTATION_USER}/.ssh/known_hosts" # TODO (20210103 gmusa): remove hardcoded port
writeToProvisioningLog "groundstation added to spacestation known hosts!"

writeToProvisioningLog "updating groundstation known hosts for passwordless SSH to spacestation"
sudo chmod 777 "${HOME}/.ssh"
ssh-keyscan "${mockspacestation_ip}" >> "${HOME}/.ssh/known_hosts"
sudo chmod 700 "${HOME}/.ssh"
writeToProvisioningLog "spacestation added to groundstation known hosts!"

writeToProvisioningLog "writing SSH connection script to '${SPACESTATION_CONTAINER_NAME}'..."
cat > ${GROUNDSTATION_ROOTDIR}/${GROUNDSTATION_SSH_SCRIPT_FILENAME} << EOL
#!/bin/bash
ssh -i ${GROUNDSTATION_SSHKEY_FILEPATH} ${GROUNDSTATION_USER}@${mockspacestation_ip}
EOL
sudo chmod 777 ${GROUNDSTATION_ROOTDIR}/${GROUNDSTATION_SSH_SCRIPT_FILENAME}
writeToProvisioningLog "SSH connection script '${GROUNDSTATION_ROOTDIR}/${GROUNDSTATION_SSH_SCRIPT_FILENAME}' written!"

# build cron job

writeToProvisioningLog "building throttled sync cron job '/tmp/${GROUNDSTATION_CRON_JOB_FILENAME}'..."
cat > /tmp/${GROUNDSTATION_CRON_JOB_FILENAME} << EOL
#!/bin/bash
echo "Starting push to spacestation..."
rsync --archive --verbose --progress --bwlimit=250 -e "ssh -i ${GROUNDSTATION_SSHKEY_FILEPATH}" ${GROUNDSTATION_ROOTDIR}/toSpaceStation/* ${GROUNDSTATION_USER}@${mockspacestation_ip}:fromGroundStation
echo "Starting pull from spacestation..."
rsync --archive --verbose --progress --bwlimit=250 -e "ssh -i ${GROUNDSTATION_SSHKEY_FILEPATH}" ${GROUNDSTATION_USER}@${mockspacestation_ip}:toGroundStation/* ${GROUNDSTATION_ROOTDIR}/fromSpaceStation
EOL
sudo chmod 777 /tmp/${GROUNDSTATION_CRON_JOB_FILENAME}
writeToProvisioningLog "wrote throttled sync cron job!"

writeToProvisioningLog "building unthrottled sync cron job '/tmp/${GROUNDSTATION_CRON_JOB_UNTHROTTLED_FILENAME}'..."
cat > /tmp/${GROUNDSTATION_CRON_JOB_UNTHROTTLED_FILENAME} << EOL
#!/bin/bash
echo "Starting push to spacestation..."
rsync --archive --verbose --progress -e "ssh -i ${GROUNDSTATION_SSHKEY_FILEPATH}" ${GROUNDSTATION_ROOTDIR}/toSpaceStation/* ${GROUNDSTATION_USER}@${mockspacestation_ip}:fromGroundStation
echo "Starting pull from spacestation..."
rsync --archive --verbose --progress -e "ssh -i ${GROUNDSTATION_SSHKEY_FILEPATH}" ${GROUNDSTATION_USER}@${mockspacestation_ip}:toGroundStation/* ${GROUNDSTATION_ROOTDIR}/fromSpaceStation
EOL
sudo chmod 777 /tmp/${GROUNDSTATION_CRON_JOB_UNTHROTTLED_FILENAME}
writeToProvisioningLog "wrote unthrottled sync cron job!"

writeToProvisioningLog "scheduling cron job..."
echo "* * * * * /usr/bin/flock -w 0 /tmp/sync-to-spacestation-job.lock /tmp/${GROUNDSTATION_CRON_JOB_FILENAME} >> $GROUNDSTATION_LOGS_DIR/sync-to-spacestation.log 2>&1" > /tmp/sync-to-spacestation-job
crontab /tmp/sync-to-spacestation-job
sudo service cron start
writeToProvisioningLog "cron job scheduled!"

# ********************************************************
# Build SSH and RSYNC Jobs: END
# ********************************************************

figlet Azure Mock Spacestation

echo ""
echo ""
echo "Welcome to the Mock Spacestation (https://github.com/azure/mock-spacestation) v2.1!"
echo ""
echo "This environment emulates the configuration and networking constraints observed by the Microsoft Azure Space Team while developing their genomics experiment to run on the International Space Station."
echo ""
echo "You are connected to the Groundstation:"
echo "     - to send a file to the Spacestation, place it in the '$GROUNDSTATION_OUTBOX_DIR' directory"
echo "     - incoming files from the Spacestation will be in the '$GROUNDSTATION_INBOX_DIR' directory"
echo ""
echo "To connect to the Spacestation: '${GROUNDSTATION_ROOTDIR}/ssh-to-spacestation.sh'"
echo "     - files received from the Groundstation will be in '/home/$GROUNDSTATION_USER/fromGroundStation/' directory"
echo "     - to send a file to the Groundstation, place it in the '/home/$GROUNDSTATION_USER/toGroundStation/' directory"
echo ""
echo "Happy Space Deving!"
echo ""
cd "$GROUNDSTATION_ROOTDIR" || exit
