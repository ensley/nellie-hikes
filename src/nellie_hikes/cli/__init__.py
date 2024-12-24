import os
from pathlib import Path

import click

from nellie_hikes.__about__ import __version__
from nellie_hikes.scrape import run


@click.group(context_settings={"help_option_names": ["-h", "--help"]}, invoke_without_command=True)
@click.version_option(version=__version__, prog_name="nellie-hikes")
def nellie_hikes():
    click.echo("Hello world!")


@nellie_hikes.command()
def scrape():
    user = os.environ.get("NELLIE_SITE_USER")
    pw = os.environ.get("NELLIE_SITE_PASSWORD")
    user_file = os.environ.get("NELLIE_SITE_USER_FILE")
    pw_file = os.environ.get("NELLIE_SITE_PASSWORD_FILE")
    if user is None and user_file is not None:
        user = Path(user_file).read_text()
    if pw is None and pw_file is not None:
        pw = Path(pw_file).read_text()

    if user is None or pw is None:
        raise ValueError("Username and/or password are required.")

    run(user, pw)
