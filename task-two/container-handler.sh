#!/bin/sh

# Container Name
PRIVILEGED_CONTAINER_NAME="upper-container"

# Run a command in a new priviliged container
docker run -d --name $PRIVILEGED_CONTAINER_NAME --privileged=true dind-with-apparmor

# Function to kill privileged conatiner up on dcoker stack remove
kill_container() {
  docker stop $PRIVILEGED_CONTAINER_NAME
  docker rm $PRIVILEGED_CONTAINER_NAME
  exit 0
}

# When shell receives SIGTERM signal it will run the handler 
trap 'kill_container' SIGTERM

# Wait till shell gets signal
while true ; do
  echo "Waiting for docker stack remove signal...."
  sleep 10
done