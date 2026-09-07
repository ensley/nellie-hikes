FROM python:3.12-slim
LABEL authors="john"

# Install Firefox from Mozilla.
# The slim base doesn't ship curl/gpg, so install them alongside Firefox.
# --no-install-recommends keeps Firefox from pulling in optional extras.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log \
    apt-get update -qq > /dev/null && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends \
        ca-certificates curl gnupg > /dev/null && \
    # Create a directory to store APT repository keys, repository lists, and preferences if they don't exist
    install -d -m 0755 /etc/apt/keyrings /etc/apt/preferences.d /etc/apt/sources.list.d > /dev/null && \
    # Import the Mozilla APT repository signing key
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg |  \
    gpg --dearmor --no-tty -o /etc/apt/keyrings/packages.mozilla.org.gpg > /dev/null && \
    # Add the Mozilla APT repository to the APT sources list
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" | \
    tee /etc/apt/sources.list.d/packages.mozilla.org.list > /dev/null && \
    # Configure APT to prioritize packages from the Mozilla repository
    echo "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n\n" | tee /etc/apt/preferences.d/mozilla > /dev/null && \
    # Update your package list and install the Firefox .deb package
    apt-get update -qq > /dev/null && \
    # Pin Firefox to a known-good version so it stays in sync with the pinned
    # geckodriver below. Bump both together (and check geckodriver's
    # firefox-compatibility note) when upgrading.
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends \
        libc-bin firefox=155.0.1~build1 > /dev/null

RUN curl -fL -o /tmp/geckodriver.tar.gz \
         https://github.com/mozilla/geckodriver/releases/download/v0.37.1/geckodriver-v0.37.1-linux64.tar.gz \
 && tar -xzf /tmp/geckodriver.tar.gz -C /tmp/ \
 && chmod +x /tmp/geckodriver \
 && mv /tmp/geckodriver /usr/local/bin/ \
 && rm /tmp/geckodriver.tar.gz

WORKDIR /app
COPY . /app/

# Install the project (and its deps) directly into the image's site-packages.
# No hatch at runtime -- we only need to *run* the CLI, not manage envs.
RUN pip install --no-cache-dir .

# What the container should run when it is started.
ENTRYPOINT ["nellie-hikes", "scrape"]
