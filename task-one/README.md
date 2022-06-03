# Task One

Deploy a docker swarm stack that would run a container with `privileged` mode. Once deployed, this privileged container should adhere to the lifecycle of the docker stack.
i.e: `docker stack rm <stack_name>` should remove the service (including the privileged container), and possibly any volumes/networks created.

> Note: _Pick any container image to demonstrate this._
