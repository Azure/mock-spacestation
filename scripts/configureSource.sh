#!/bin/bash

# setup trials directory
mkdir /home/azureuser/trials
echo "Hello! It is currently $(date) on the virtualMachineNameDefaultValue. Happy hacking!" >> /home/azureuser/trials/hello.txt
chown azureuser /home/azureuser/trials

# write private key
echo "privateKeyDefaultValue" >> /home/azureuser/.ssh/mockSpacestationPrivateKey
chmod 600 /home/azureuser/.ssh/mockSpacestationPrivateKey

# write destination machine keys to known_hosts
ssh-keyscan hostToSyncDefaultValue >> /root/.ssh/known_hosts

# setup sync script
mkdir /home/azureuser/scripts
touch /home/azureuser/scripts/sync.sh
cat > /home/azureuser/scripts/sync.sh <<EOF
#!/bin/bash
sudo rsync -arvz --bwlimit=250 -e "ssh -i /home/azureuser/.ssh/mockSpacestationPrivateKey" --verbose --progress /home/azureuser/trials/* azureuser@hostToSyncDefaultValue:/home/azureuser/trials
EOF
chmod +x /home/azureuser/scripts/sync.sh

# register cron
echo "* * * * * /home/azureuser/scripts/sync.sh >> /home/azureuser/azure-sync.log 2>&1" >> newJob
crontab newJob
crontab -l
