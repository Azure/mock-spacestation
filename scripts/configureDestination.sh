#!/bin/bash

# setup trials directory
mkdir /home/azureuser/trials
chown azureuser /home/azureuser/trials

# write private key
echo "privateKeyDefaultValue" >> /home/azureuser/.ssh/mockSpacestationPrivateKey
chmod 600 /home/azureuser/.ssh/mockSpacestationPrivateKey
