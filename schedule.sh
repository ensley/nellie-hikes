#!/bin/bash
# Weekly scrape run, invoked by Synology Task Scheduler.
#
# Why this is more than `docker-compose up`:
#   * `docker-compose up` writes its progress lines ("Creating", "Attaching",
#     "Container ... Created") to STDERR. Synology's Task Scheduler treats any
#     stderr output as an error and emails you every week even on a clean run.
#     We send ALL output to a log file so the scheduler sees a silent success.
#   * `--exit-code-from app` makes compose return the scraper's *real* exit code,
#     so a genuine failure still propagates (and still alerts you), while a
#     normal run exits 0 and stays quiet.

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
    docker-compose up --abort-on-container-exit --exit-code-from app --remove-orphans
    code=$?
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') finished with exit code ${code} ==="
} >>"$log" 2>&1

exit "${code}"
