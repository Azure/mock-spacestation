#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Used on a blank VM Sets via Azure templates to deploy the Mock SpaceStation environment.  Mostly a wrapper for deployGroundStation.sh
# Syntax: ./runFromAzureTemplate.sh

curl -O "https://raw.githubusercontent.com/azure/mock-spacestation/.devcontainer/setupScripts/deployGroundStation.sh"
. ./deployGroundStation.sh