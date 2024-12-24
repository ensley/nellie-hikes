import logging
import os
import sys
from datetime import datetime
from pathlib import Path

import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as ec
from selenium.webdriver.support.wait import WebDriverWait

_BASE_URL = "https://ddj.petssl.com/admin/images?v=gallery&setrows=1000"
_LOGIN_URL = "https://ddj.petssl.com/login"

logging.basicConfig(
    stream=sys.stdout,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def set_options() -> Options:
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    return options


def navigate_site(wait: WebDriverWait, user: str, pw: str):
    elem_id = wait.until(ec.presence_of_element_located((By.ID, "text_username_new")))
    elem_id.clear()
    elem_id.send_keys(user)

    elem_pw = wait.until(ec.presence_of_element_located((By.ID, "password_password_new")))
    elem_pw.clear()
    elem_pw.send_keys(pw)

    elem_submit = wait.until(ec.presence_of_element_located((By.XPATH, "//button[@type='submit']")))
    elem_submit.click()

    elem_gallery = wait.until(ec.presence_of_element_located((By.ID, "ajax_update")))
    links = [
        el.get_attribute("href")
        for el in elem_gallery.find_elements(
            By.XPATH,
            "//a[contains(@href, 's3.amazonaws.com')]",
        )
    ]
    timestamps = [el.text for el in elem_gallery.find_elements(By.CLASS_NAME, "ph_details")]

    return links, timestamps


def crawl_site(user, pw):
    driver = webdriver.Firefox(options=set_options())
    driver.get(_BASE_URL)
    wait = WebDriverWait(driver, 30)
    try:
        links, timestamps = navigate_site(wait, user, pw)
    finally:
        driver.quit()

    return links, timestamps


def download_images(links, timestamps):
    imgdir = Path("img")
    imgdir.mkdir(exist_ok=True)
    for img_url, ts in zip(links, timestamps):
        filename = img_url.split("/")[-1]
        path = imgdir / filename
        logger.info(filename)
        if not path.exists():
            img_data = requests.get(img_url, timeout=30)
            logger.info("DOWNLOADING %s", filename)
            with open(path, "wb") as fh:
                fh.write(img_data.content)

            photo_time = datetime.strptime(ts.strip(), "%b %d, %Y %H:%M%p")
            os.utime(path, (photo_time.timestamp(), photo_time.timestamp()))

    return imgdir


def run(user, pw):
    links, timestamps = crawl_site(user, pw)
    download_images(links, timestamps)
