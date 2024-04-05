# swarm-cronjob
crazymax swarm cronjob config files

- https://crazymax.medium.com/create-jobs-on-a-time-based-schedule-on-swarm-94258f95c905
- https://crazymax.dev/swarm-cronjob/
- https://github.com/crazy-max/swarm-cronjob


# Deploy
```bash
docker stack deploy -c swarm-compose.yml swarm_cronjob
```

# Usage

When swarm-cronjob is ready, create a new stack to be scheduled like this one:

```yml
version: "3.2"

services:
  test:
    image: busybox
    command: date
    deploy:
      mode: replicated
      replicas: 0
      labels:
        - "swarm.cronjob.enable=true"
        - "swarm.cronjob.schedule=* * * * *"
        - "swarm.cronjob.skip-running=false"
      restart_policy:
        condition: none
```

You can include any configuration as long as you abide with the following conditions:

- Set command to run the task command
- Set mode to replicated (default)
- Set replicas to 0 to avoid running task as soon as the service is deployed
- Set restart_policy.condition to none. This is needed for a cronjob, otherwise the task will restart automatically
- Add Docker labels to tell swarm-cronjob that your service is a cronjob