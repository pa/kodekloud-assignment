#!/bin/sh

# Container Name
PRIVILEGED_CONTAINER_NAME="privileged"
NON_PRIVILEGED_CONTAINER_NAME="non-privileged"

# Run a command in a new priviliged container
docker run -d --name $PRIVILEGED_CONTAINER_NAME --privileged=true ubuntu sleep infinity

# Run a command in a new non-priviliged container
docker run -d --name $NON_PRIVILEGED_CONTAINER_NAME ubuntu sleep infinity

# Function to kill privileged conatiner up on dcoker stack remove
kill_containers() {
  docker stop $PRIVILEGED_CONTAINER_NAME
  docker rm $PRIVILEGED_CONTAINER_NAME
  docker stop $NON_PRIVILEGED_CONTAINER_NAME
  docker rm $NON_PRIVILEGED_CONTAINER_NAME
  exit 0
}

# When shell receives SIGTERM signal it will run the handler 
trap 'kill_containers' SIGTERM

# Wait till shell gets signal
while true ; do
  echo "Waiting for docker stack remove signal...."
  sleep 10
done