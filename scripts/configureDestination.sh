#!/bin/bash
#
# configureDestination.sh - applied to a virtual machine by an Azure Custom Script Extension resource to
#   1. create a /home/azureuser/trials directory
#   2. write a private key to /home/azureuser/.ssh/mockSpacestationPrivateKey
#   *. use Bicep's replace() function to inject values wherever privateKeyDefaultValue appears

# 1. setup trials directory
mkdir /home/azureuser/trials
chown azureuser /home/azureuser/trials

# 2. write private key
echo "privateKeyDefaultValue" >> /home/azureuser/.ssh/mockSpacestationPrivateKey
chmod 600 /home/azureuser/.ssh/mockSpacestationPrivateKey
