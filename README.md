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
