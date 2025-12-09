# swarm-cronjob

Lightweight wrapper around the official [crazymax/swarm-cronjob](https://github.com/crazy-max/swarm-cronjob) controller.

This repo gives you:

- A small, configurable Swarm stack for the cron controller itself
- A `.quick-start.sh` helper script to configure and deploy it

Once deployed, `swarm-cronjob` watches your Swarm for services with special labels and starts tasks on a cron schedule.

Useful references for the underlying project:

- https://crazymax.medium.com/create-jobs-on-a-time-based-schedule-on-swarm-94258f95c905
- https://crazymax.dev/swarm-cronjob/
- https://github.com/crazy-max/swarm-cronjob

---

## 1. Requirements

- Docker Swarm initialized (`docker swarm init`)
- You are on a Swarm **manager** node (the controller must run on a manager)

---

## 2. Configuration (.env.template)

The stack is parameterized via `.env` (created from `.env.template`):

```env
STACK_NAME=swarm_cronjob
IMAGE_NAME=crazymax/swarm-cronjob
IMAGE_VERSION=latest
TZ=Europe/Berlin
LOG_LEVEL=info
LOG_JSON=false
```

- `STACK_NAME` – Swarm stack name for the controller
- `IMAGE_NAME` / `IMAGE_VERSION` – image and tag for the controller
- `TZ` – timezone used for cron evaluation
- `LOG_LEVEL` / `LOG_JSON` – logging format and verbosity

You normally do **not** need to edit `swarm-compose.yml` directly; `.quick-start.sh` wires `.env` into it for you.

---

## 3. Quick Start (`.quick-start.sh`)

From the repo root:

```bash
chmod +x .quick-start.sh   # once
./.quick-start.sh
```

The script will:

1. Ensure Docker is available
2. Ensure `.env` exists (creating it from `.env.template` on first run)
3. Show the current configuration
4. Present a small menu:

   - **1) Edit .env manually** – opens `.env` in `$EDITOR` (or `nano`/`vi`)
   - **2) Guided configuration** – prompts you for:
     - `STACK_NAME`
     - `IMAGE_NAME` / `IMAGE_VERSION`
     - `TZ`
     - `LOG_LEVEL`, `LOG_JSON`
   - **3) Deploy / update swarm-cronjob stack** – runs:

     ```bash
     docker stack deploy -c swarm-compose.yml "$STACK_NAME"
     ```

   - **4) Show stack status** – `docker stack services $STACK_NAME`
   - **5) Remove stack** – `docker stack rm $STACK_NAME`
   - **6) Exit**

This is the recommended way to install and manage the cron controller.

---

## 4. Manual Deploy (optional)

If you prefer not to use `.quick-start.sh`:

```bash
cp .env.template .env               # or create .env manually
# edit .env as needed

STACK_NAME=swarm_cronjob           # or your chosen name
docker stack deploy -c swarm-compose.yml "$STACK_NAME"
```

The controller itself is defined in `swarm-compose.yml` using those env vars.

---

## 5. Using cron labels in other stacks

Once the `swarm-cronjob` controller is running, any **other** Swarm service can be turned into a cronjob by:

1. Setting `deploy.mode: replicated`
2. Setting `deploy.replicas: 0` (so it does not run continuously)
3. Setting `deploy.restart_policy.condition: none` (cron starts tasks, they should not auto-restart)
4. Adding the cron labels:

```yaml
deploy:
  mode: replicated
  replicas: 0
  labels:
    - "swarm.cronjob.enable=true"
    - "swarm.cronjob.schedule=0 */6 * * *"    # example: every 6 hours
    - "swarm.cronjob.skip-running=false"
  restart_policy:
    condition: none
```

The actual service definition can be anything you like as long as:

- It has a `command` that performs the job (e.g. `python script.py`)
- It follows the constraints above

### Example (generic)

```yaml
services:
  my-periodic-job:
    image: busybox
    command: date
    deploy:
      mode: replicated
      replicas: 0
      labels:
        - "swarm.cronjob.enable=true"
        - "swarm.cronjob.schedule=*/5 * * * *"   # every 5 minutes
        - "swarm.cronjob.skip-running=false"
      restart_policy:
        condition: none
```

As soon as this stack is deployed, the `swarm-cronjob` controller will start tasks for `my-periodic-job` according to the schedule.

---

## 6. Notes

- This repo does **not** define any application-specific jobs; it only runs the controller.
- Other Swarm stacks (e.g. a webscraper in `swarm-pricetracker`) are responsible for adding the labels shown above.