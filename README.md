# nellie-hikes

Scrape pictures of my dog on her weekly hikes.

![Nellie on one of her hikes](https://s3.amazonaws.com/petssl.com/ddj/images/uploads/Content/2C091521-936E-4B3D-BC14-13C021C79F85.jpg)

-----

## Project Goal

To get my dog Nellie some extra exercise, we use a local dog walking service that picks her up in the morning once a week, takes her and some other neighborhood dogs for a hike, and drops her back off at home. They take photos of the dogs during each hike and make them available as a gallery on their website. I wanted to save those photos without having to log in to the site and manually download them each week.

This small project scrapes the photo gallery and downloads any photos that I don't already have on my filesystem. It uses [Selenium](https://www.selenium.dev/) to automate the login and navigation of the website (the gallery is behind a login), and [requests](https://requests.readthedocs.io/en/latest/) to grab the photos. It runs as a [Docker container](https://docs.docker.com/) on the Synology NAS at home, triggered once a week by the NAS's Task Scheduler on the evening of Nellie's hike day.

## How it works

* The image bundles a headless Firefox plus a matching [geckodriver](https://github.com/mozilla/geckodriver) (both pinned in the [`Dockerfile`](Dockerfile)) so Selenium can drive the site.
* [`schedule.sh`](schedule.sh) is the entry point the NAS's Task Scheduler runs each week. It loads `.env`, runs the scraper as a **throwaway one-off container** (`docker-compose run --rm`), logs everything to `scrape.log`, and exits with the scraper's real exit code. See the comments in that file for why it's shaped this way (it silences two spurious Synology emails — a Task Scheduler stderr alert and a Container Manager "stopped unexpectedly" alert — while still surfacing genuine failures).
* Downloaded photos land in `DOCKER_PHOTO_DIR` on the host; a photo that already exists on disk is skipped.

## Setup

1. Clone this repository.

   ```bash
   git clone git@github.com:ensley/nellie-hikes.git
   ```

2. Create a `.env` file at the root of the project directory containing the following:

   ```env
   NELLIE_SITE_USER=XXXXX
   NELLIE_SITE_PASSWORD=XXXXX
   DOCKER_PHOTO_DIR=XXXXX
   ```

   `NELLIE_SITE_USER` and `NELLIE_SITE_PASSWORD` are the website username and password. `DOCKER_PHOTO_DIR` is the directory on the host machine where the downloaded files will be stored; running locally, this might be `DOCKER_PHOTO_DIR=./img`. Running on the NAS it's `DOCKER_PHOTO_DIR=/volume1/photo/nellie_hikes`. This file stays out of git and lives only on the machine that runs the scraper.

3. Build the image.

   ```bash
   source ./.env && docker-compose build
   ```

## Running it

Run the scraper once (this is exactly what the weekly schedule does):

```bash
bash schedule.sh
```

Output goes to `scrape.log`. To watch a run live instead, you can run the one-off container directly:

```bash
source ./.env && docker-compose run --rm app
```

## Scheduling on the NAS

The weekly run is driven by the Synology **Task Scheduler** (Control Panel → Task Scheduler), not by cron inside the container. Create a user-defined script task that runs on the desired day/time with the command:

```bash
bash /volume1/docker/projects/nellie-hikes/schedule.sh
```

## Deploying changes

The NAS holds a git clone that is only ever *pulled to* — never edit code directly on the NAS. The loop is:

1. Make and test changes locally, then commit and push to `main`.

2. On the NAS, pull and rebuild the image:

   ```bash
   ssh ensley-nas
   cd /volume1/docker/projects/nellie-hikes
   git pull --ff-only origin main
   source .env && docker-compose build
   ```

   The next scheduled run (or `bash schedule.sh`) picks up the rebuilt image automatically.

Notes:

* `docker` lives at `/usr/local/bin` on the NAS, which isn't always on a non-interactive shell's `PATH` — export it if a command isn't found.
* `core.fileMode false` is set on the NAS clone so executable-bit differences don't block pulls.
* Synology's Task Scheduler drops a root-owned `synoscheduler/` directory inside the project folder; it's excluded from the Docker build context in [`.dockerignore`](.dockerignore).

## License

`nellie-hikes` is distributed under the terms of the [MIT](https://spdx.org/licenses/MIT.html) license.
