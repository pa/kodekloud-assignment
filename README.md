# kodekloud-assignment

This repo contains solutions for two tasks,

1. Deploy a docker swarm stack that would run a container with `privileged` mode. For more details check [here](task-one/README.md).

2. Run a ubuntu based docker container which can inturn run docker inside `(docker in docker mode)`. For more details check [here](task-two/README.md).

## Directory Structure

```bash
.
├── README.md
├── docker-compose.yml
├── task-one
│   ├── Dockerfile
│   ├── README.md
│   ├── arch_diagram.png
│   ├── container-handler.sh
│   └── docker-compose.yml
└── task-two
    ├── Dockerfile
    ├── README.md
    ├── apparmor-profiles
    │   ├── audit-all-writes
    │   └── deny-all-writes
    ├── arch_diagram.png
    ├── container-handler.sh
    └── docker-compose.yml
```

- [docker-compose.yml](docker-compose.yml) - Used to deploy docker swarm stack with two services (task one and task two) in a docker swarm cluster.
- [task-one](task-one)
  - [Dockerfile](task-one/Dockerfile) - Copies [container-handler](task-one/container-handler.sh) script into the filesystem of the container and execute it within the container
  - [README.md](task-one/README.md) - Contains instructions to build image and deploy docker swarm stack in swarm cluster
  - [arch_diagram.png](task-one/arch_diagram.png) - Architecture diagram for task one docker swarm stack
  - [container-handler.sh](task-one/container-handler.sh) - Creates two sibiling containers, one with  `priviliged` mode enabled. Also waits for `docker stack rm <stack_name>` signal and kills the sibiling when `SIGTERM` is received
  - [docker-compose.yml](task-one/docker-compose.yml) - It has one service and uses an existing network to deploy `container-handler` conatiner to bring up sibiling containers, one with  `priviliged` mode enabled
- [task-two](task-two)
  - [Dockerfile](task-two/Dockerfile) - Copies [apparmor profiles](task-two/apparmor-profiles/) and [container-handler](task-two/container-handler.sh) script into the filesystem of the container and execute the script within container
  - [README.md](task-two/README.md) - Contains instructions to build image and deploy docker swarm stack in swarm cluster
  - [apparmor-profiles](task-two/apparmor-profiles/)
    - [audit-all-writes](task-two/apparmor-profiles/audit-all-writes) - This profile will audit all the writes `(i.e creating dirs/files)` happening within the container and logs it to the kernel log
    - [deny-all-writes](task-two/apparmor-profiles/deny-all-writes) - This profile will deny all the writes `(i.e creating dirs/files)` happening within the container and logs it to the kernel log
  - [arch_diagram.png](task-two/arch_diagram.png) - Architecture diagram for task two docker swarm stack
  - [container-handler.sh](task-two/container-handler.sh) - Creates one sibiling upper containers with  `priviliged` mode, updates/installs apparmor packages, copies apparmor profiles to `/etc/apparmo.d/` in the upper container, creates two child inner conatiner with apparmor profiles applied. Also waits for `docker stack rm <stack_name>` signal and kills the sibiling upper conatiner `(including child inner containers)` when `SIGTERM` is received
  - [docker-compose.yml](task-two/docker-compose.yml) - It has one service and uses an existing network to deploy `container-handler` conatiner to bring up sibiling upper container with  `priviliged` mode enabled and two child inner container

## Deploy tasks to Swarm Cluster

In this section we will be deploying both the tasks [task-one](task-one) and [task-two](task-two) in swarm cluster using a single [docker-compose](docker-compose.yml) file. We can deploy this stack to any cloud platform or even a local dev machine. For this deployment I'm going to use AWS Cloud.

### Pre-requisites

#### Docker Images

- Task one service image - You can either build image using [Dockerfile](task-one/Dockerfile) (_if you also want to use custom image name and tag, make sure to change the same in [docker-compose.yml](docker-compose.yml#L12)_) or you can use my docker image in [pramodhayyappan/kk-task-one-container-handler](https://hub.docker.com/repository/docker/pramodhayyappan/kk-task-one-container-handler) in dockerhub

    ```bash
    # To build image with custom name and tag. By deafult it use latest tag
    docker build -f task-one/Dockerfile task-one -t pramodhayyappan/kk-task-one-container-handler:<tag name>
    ```

- Task two service image - You can either build image using [Dockerfile](task-one/Dockerfile) (_if you also want to use custom image name, make sure to change the same image name in [docker-compose.yml](docker-compose.yml#L23)_) or you can use my docker image in [pramodhayyappan/kk-task-two-container-handler](https://hub.docker.com/repository/docker/pramodhayyappan/kk-task-two-container-handler) in dockerhub

    ```bash
    # To build image with custom name and tag. By deafult it use latest tag
    docker build -f task-two/Dockerfile task-two -t pramodhayyappan/kk-task-two-container-handler:<tag name>
    ```

#### Cloud Infra deployment

- Assuming that you already have set up aws credentials in local machine
- Create Security Group to allow communication between nodes and make note of the sg name

    ```bash
    aws ec2 create-security-group --group-name swarm-cluster-sg --description "swarm cluster security group" --vpc-id <vpc-id>
    ```

- Create ingress rules to protocols and ports mentioned in [offical doc](https://docs.docker.com/engine/swarm/swarm-tutorial/#open-protocols-and-ports-between-the-hosts)

    ```bash
    aws ec2 authorize-security-group-ingress --group-id <sg name from previous step> --protocol tcp --port 22 --cidr <cidr ip>
    aws ec2 authorize-security-group-ingress --group-id <sg name from previous step> --protocol tcp --port 2377 --cidr <cidr ip>
    aws ec2 authorize-security-group-ingress --group-id <sg name from previous step> --protocol tcp --port 7946 --cidr <cidr ip>
    aws ec2 authorize-security-group-ingress --group-id <sg name from previous step> --protocol udp --port 7946 --cidr <cidr ip>
    aws ec2 authorize-security-group-ingress --group-id <sg name from previous step> --protocol udp --port 4789 --cidr <cidr ip>
    ```

- Create `user-data.sh` script file with below content

    ```bash
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release -y
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io  docker-compose-plugin git -y
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    ```

- Create two EC2 instances for Docker Swarm cluster

    ```bash
    aws ec2 run-instances --image-id <ami-id> --count 1 --instance-type t2.xlarge --key-name <key-pair-name> --security-group-ids <sg name from first step> --subnet-id <subnet-id> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ManagerNode}]' --user-data file://user-data.sh

    aws ec2 run-instances --image-id <ami-id> --count 1 --instance-type t2.xlarge --key-name <key-pair-name> --security-group-ids <sg name from first step> --subnet-id <subnet-id> --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WorkerNode1}]' --user-data file://user-data.sh
    ```

- Our infra structure is ready with docker installed

### Deploy docker stack

#### Deploy stack

- Create a swarm cluster by executing below command in manager node

    ```bash
    docker swarm init --advertise-addr <MANAGER-IP>
    ```

- Join worker node to the cluster by using the command from the output of init command or use `join-token` command to generate join command. The command will look like

    ```bash
    docker swarm join-token worker
    docker swarm join --token <token> <ip>:<port>
    ```

- Clone this repo to the manager node

    ```bash
    git clone https://github.com/pa/kodekloud-assignment.git

    cd kodekloud-assignment
    ```

- Deploy docker stack

    ```bash
    docker stack deploy --compose-file docker-compose.yml <stack-name>
    ```

- Stack got deployed, some useful commands to list stack, services, container and inspect container

    ```bash
    # To list docker stacks
    docker stack ls

    # To list services deployed by stack
    docker stack services <stack-name>

    # To list docker containers
    docker ps

    # to inspect docker container
    docker inspect <conatiner id or name>

    # # runs a new command on a running container
    docker exec -it <conatiner id or name> <bash or shell>
    ```

#### Demo

The demo of docker stack deployment and testing each tasks functionality

[![asciicast](https://asciinema.org/a/500320.svg)](https://asciinema.org/a/500320)