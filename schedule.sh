#!/bin/bash
# Weekly scrape run, invoked by Synology Task Scheduler.
#
# Two separate Synology notifications had to be silenced here:
#   1. The Task Scheduler emails whenever the task writes to STDERR, and
#      docker-compose prints its progress lines there. We send ALL output to a
#      log file so the scheduler sees a silent success.
#   2. Container Manager emails "Container ... stopped unexpectedly" whenever a
#      container it *monitors* stops. `docker-compose up` leaves a persistent
#      service container in Container Manager's list, so its normal exit looks
#      like an unexpected stop. `docker-compose run --rm` instead runs a
#      throwaway one-off container that is removed the moment it exits, so there
#      is no monitored container for Container Manager to flag.
#
# `run` returns the scraper's real exit code, so a genuine failure still
# propagates (and still alerts you) while a clean run exits 0 and stays quiet.
# `-T` disables TTY allocation, which the scheduler's non-interactive shell
# doesn't provide.

set -uo pipefail

cd "$(dirname "$0")" || exit 1

# Load NELLIE_SITE_USER / NELLIE_SITE_PASSWORD / DOCKER_PHOTO_DIR
set -a
# shellcheck disable=SC1091
source .env
set +a

log="scrape.log"
{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') starting nellie-hikes scrape ==="
    docker-compose run --rm -T app
    code=$?
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') finished with exit code ${code} ==="
} >>"$log" 2>&1

exit "${code}"
