#!/bin/bash
#
# configureDestination.sh - applied to a virtual machine by an Azure Custom Script Extension resource to
#   1. create a /home/azureuser/trials directory
#   2. write a private key to /home/azureuser/.ssh/mockSpacestationPrivateKey
#   3. add the destination machine's public keys to root's known_hosts
#   4. write a /home/azureusers/sync.sh script that contains an rsync command that 
#      clones the /trials directory to the destination machine
#   5. register a cron job to execute the sync.sh script on a schedule
#   *. use Bicep's replace() function to
#        inject values for wherever 'virtualMachineNameDefaultValue' appears
#        inject values for wherever 'privateKeyDefaultValue' appears
#        inject values for wherever 'hostToSyncDefaultValue' appears

# 1. setup trials directory
mkdir /home/azureuser/trials
echo "Hello! It is currently $(date) on the virtualMachineNameDefaultValue. Happy hacking!" >> /home/azureuser/trials/hello.txt
chown azureuser /home/azureuser/trials

# 2. write private key
echo "privateKeyDefaultValue" >> /home/azureuser/.ssh/mockSpacestationPrivateKey
chmod 600 /home/azureuser/.ssh/mockSpacestationPrivateKey

# 3. write destination machine keys to known_hosts
ssh-keyscan hostToSyncDefaultValue >> /root/.ssh/known_hosts

# 4. setup sync script
mkdir /home/azureuser/scripts
touch /home/azureuser/scripts/sync.sh
cat > /home/azureuser/scripts/sync.sh <<EOF
#!/bin/bash
sudo rsync -arvz --bwlimit=250 -e "ssh -i /home/azureuser/.ssh/mockSpacestationPrivateKey" --verbose --progress /home/azureuser/trials/* azureuser@hostToSyncDefaultValue:/home/azureuser/trials
EOF
chmod +x /home/azureuser/scripts/sync.sh

# 5. register cron
echo "* * * * * /home/azureuser/scripts/sync.sh >> /home/azureuser/azure-sync.log 2>&1" >> newJob
crontab newJob
