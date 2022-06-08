#!/bin/sh

# Container Name
PRIVILEGED_CONTAINER_NAME="upper-container"

# Run a command in a new priviliged container
docker run -itd --name $PRIVILEGED_CONTAINER_NAME --privileged cruizba/ubuntu-dind

# Install apparmor inside upper container
docker exec -d $PRIVILEGED_CONTAINER_NAME bash -c 'apt-get update; apt-get install apparmor apparmor-utils -y'

# Copy apparmor profiles into container's /etc/apparmor.d dir
docker cp ./app/apparmor-profiles/ $PRIVILEGED_CONTAINER_NAME:/etc/apparmor.d

# Sleep for 20 secs to completed installation of apparmor and its utils
sleep 20

# Restart apparmor service inside upper container
docker exec -d $PRIVILEGED_CONTAINER_NAME bash -c 'service apparmor restart'

# Run inner container with apparmor profile
docker exec -d $PRIVILEGED_CONTAINER_NAME bash -c 'docker run -itd --name deny-all-writes --security-opt "apparmor=deny-all-writes" ubuntu bash -c "touch test.txt; bash"'
docker exec -d $PRIVILEGED_CONTAINER_NAME bash -c 'docker run -itd --name audit-all-writes --security-opt "apparmor=audit-all-writes" ubuntu bash -c "touch test.txt; bash"'

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