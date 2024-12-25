# nellie-hikes

Scrape pictures of my dog on her weekly hikes.

![Nellie on one of her hikes](https://s3.amazonaws.com/petssl.com/ddj/images/uploads/Content/2C091521-936E-4B3D-BC14-13C021C79F85.jpg)

-----

## Project Goal

To get my dog Nellie some extra exercise, we use a local dog walking service that picks her up in the morning once a week, takes her and some other neighborhood dogs for a hike, and drops her back off at home. They take photos of the dogs during each hike and make them available as a gallery on their website. I wanted to save those photos without having to log in to the site and manually download them each week.

This small project scrapes the photo gallery and downloads any photos that I don't already have on my filesystem. It uses [Selenium](https://www.selenium.dev/) to automate the navigation of the website, and [requests](https://requests.readthedocs.io/en/latest/) to grab the photos. I also had some additional requirements:

* I wanted to wrap this in a [Docker container](https://docs.docker.com/) so that I could run it in isolation on the Synology NAS I have set up at home.
* I needed to schedule it to run once a week, on the day she's scheduled to be picked up, so that I can have the photos later the same day.

## Instructions

1. Clone this repository.

   ```bash
   $ git clone git@github.com:ensley/nellie-hikes.git
   ```

2. Create a `.env` file at the root of the project directory containing the following:

   ```env
   NELLIE_SITE_USER=XXXXX
   NELLIE_SITE_PASSWORD=XXXXX
   DOCKER_PHOTO_DIR=XXXXX
   ```

   `NELLIE_SITE_USER` and `NELLIE_SITE_PASSWORD` are the website username and password. `DOCKER_PHOTO_DIR` is the directory on the host machine where the downloaded files will be stored; running locally, this might be `DOCKER_PHOTO_DIR=./img` to create a `img` directory at the project root. Running on the NAS, this should be `DOCKER_PHOTO_DIR=/volume1/photo/nellie_hikes` in my case.

3. Run the container with

   ```bash
   $ source ./.env && docker-compose up
   ```

## License

`nellie-hikes` is distributed under the terms of the [MIT](https://spdx.org/licenses/MIT.html) license.
