trickle -s -d 5 -u 5 -L 400 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $STATION_SSH_KEY $STATION_USERNAME@$STATION_CONTAINER_NAME