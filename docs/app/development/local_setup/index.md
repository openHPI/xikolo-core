
# Local setup

This guide will help you set up everything you need for running `xikolo` and start developing right away.

## Prerequisites

### Repository

If you are part of the Xikolo core team at the HPI, you will need access to the project repository and [GitLab](https://gitlab.hpi.de/groups/openhpi/).

- You need at least read access for the `xikolo` group or direct (read) access to the `web` repository.
- Ensure that you have created an SSH key pair (*ed25519* is highly recommended), and add your public key to your GitLab [profile](https://gitlab.hpi.de/-/profile/keys).

=== "Mac"

    Optional: To avoid having to enter your password each time you can add your key to your local machine using the following command.

    ```console
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    ```

### Software

Xikolo can be installed on Debian-based Linux or Mac computers. First, make sure the following software is installed on your machine:

**Git**: Version control

=== "Debian / Ubuntu"

    ```console
    sudo apt install git
    ```

=== "Mac"

    Will be installed automatically on first use.

**RVM**: Ruby version manager

Install RVM as described in

- [Basic installation guide](https://rvm.io/)
- [Full installation guide](https://rvm.io/rvm/install/)

**Ruby 3.2**: The programming language for most of our services

=== "Debian / Ubuntu"

    ```console
    rvm install 3.4.2
    ```

=== "Mac"

    ```console
    rvm install 3.4.2
    ```

**Bundler**: Ruby's dependency manager

```console
gem install bundler -v '~> 2.0'
```

**NodeJS 20**: Needed for installing and compiling frontend dependencies

=== "Debian / Ubuntu"

    There are two options:

    1. *Use apt*

        Setup correct [APT repository](https://github.com/nodesource/distributions) for the needed Node version.

        Install Node:

        ```console
        sudo apt install nodejs
        ```

    2. *Use NVM*

        Follow install documentation [from `nvm` on GitHub](https://github.com/nvm-sh/nvm#installing-and-updating)

        ```console
        nvm install
        ```

=== "Mac"

    Use [NVM](https://github.com/creationix/nvm)
    Can be installed using [Homebrew](https://brew.sh/):

    ```console
    brew install nvm
    mkdir ~/.nvm
    ```

    Follow install documentation [from nvm on GitHub](https://github.com/nvm-sh/nvm#installing-and-updating)

    ```console
    nvm install
    ```

**Yarn**: Another dependency manager for NodeJS

Since Node 16, manually installing `yarn` can be completely substituted by using the bundled `corepack`. This will create stubs for `yarn` on your system. When running `yarn` inside a Node project, the corepack stub will check the `packageManager` fields in `package.json`, and automatically download and use the exact needed version of `yarn`, and otherwise use the latest 1.x version.

```console
(sudo) corepack enable [--install-directory ~/.local/bin]
yarn install
```

!!! note

    `--install-directory` can be used to install the stubs in a specific directory, such as `/usr/local/bin`, or without sudo `~/.local/bin`. This path must be in `PATH`.

**RabbitMQ**: Asynchronous messaging / event broadcasting between services

!!! tip

    There is a RabbitMQ Web-UI (if you install it): [http://localhost:15672](http://localhost:15672/)

    username: `guest`
    password: `guest`

=== "Debian / Ubuntu"

    ```console
    sudo apt install rabbitmq-server
    ```

    Optionally, install the Web UI:

    ```console
    sudo rabbitmq-plugins enable rabbitmq_management
    ```

=== "Mac"

    ```console
    brew install rabbitmq
    ```

    To start as a service:

    ```console
    brew services start rabbitmq
    ```

    Optionally, install the rabbitmq_management:

    ```console
    /usr/local/opt/rabbitmq/sbin/rabbitmq-plugins enable rabbitmq_management
    ```

**PostgreSQL 17 (or later)**: A relational database

!!! note
    The version used in production is still PostgreSQL 16.
    Potential differences need to be considered,
    e.g. when using a specific feature that is not available.

=== "Debian / Ubuntu"

    ```console
    sudo apt install postgresql
    ```

=== "Mac"

    ```console
    brew install postgresql@17
    brew link postgresql@17
    ```

    To start as a service:

    ```console
    brew services start postgresql@17
    ```

**Redis (7.0)**: A key-value store for caching and other use-cases

!!! note
    Increase database number (databases option) to >8000 (e.g. 8192)

=== "Debian / Ubuntu"

    Install Redis from upstream archive to get a 7.0 version: <https://redis.io/docs/getting-started/installation/install-redis-on-linux/>.

    Edit the file `/etc/redis/redis.conf`:

    - Replace `databases 16` with `databases 8192`
    - Replace `supervised no` with `supervised systemd`

    Finally, restart Redis for the changes to take effect:

    ```console
    sudo systemctl restart redis-server
    ```

=== "Mac"

    ```console
    brew install redis
    ```

    To start as a service:

    ```console
    brew services start redis
    ```

    Edit the file `redis.conf`:

    ```console
    nano $(brew --prefix)/etc/redis.conf
    ```

    - Replace `databases 16` with `databases 8192`

    Restart Redis:

    ```console
    brew services restart redis
    ```

**Imagemagick 6**: An image manipulation toolkit

=== "Debian / Ubuntu"

    ```console
    sudo apt install imagemagick
    ```

=== "Mac"

    ```console
    brew install imagemagick@6
    ```

**Minio**: A local S3 server - needed for services that store files

=== "Debian / Ubuntu"

    - Download [server binary and access setup guide](https://www.minio.io/downloads.html#download-server)
    - Install the binary to `/usr/local/bin`.
    - Create a directory where S3 can store its data, e.g. `xi/s3-data` in your home directory.

    The Minio server can then be started using:

    ```console
    minio server ~/xi/s3-data
    ```

    You can also make it a user space service. Create these directories:

    ```console
    mkdir -p ~/.local/lib/minio
    mkdir -p ~/.config/systemd/user
    ```

    Add the file `~/.config/systemd/user/minio.service` as follows:

    ```ini
    [Unit]
    Description=MinIO
    Documentation=https://docs.min.io
    Wants=network-online.target
    After=network-online.target
    AssertFileIsExecutable=/usr/local/bin/minio

    [Service]
    WorkingDirectory=/home/YOUR_USERNAME/.local/lib/minio
    ExecStart=/usr/local/bin/minio server --address localhost:9000 /home/YOUR_USERNAME/.local/lib/minio
    Restart=always
    LimitNOFILE=65536
    TimeoutStopSec=infinity
    SendSIGKILL=no

    [Install]
    WantedBy=default.target
    ```

    You can then use `systemctl`:

    ```console
    systemctl --user start minio
    systemctl --user status minio
    systemctl --user stop minio
    ```

=== "Mac"

    ```console
    brew install minio
    ```

    To start as a service:

    ```console
    brew services start minio
    ```

**Service runtime dependencies**: The following system packages are needed to build or run our services

=== "Debian / Ubuntu"

    ```console
    sudo apt install \
    cmake \
    ffmpeg \
    gir1.2-gdkpixbuf-2.0 \
    gir1.2-rsvg-2.0 \
    libcurl4 \
    libffi-dev \
    libgirepository1.0-dev \
    libgit2-dev \
    libidn11-dev \
    libpq-dev \
    librsvg2-dev \
    libsodium23 \
    libv8-dev \
    libxml2-dev \
    libxslt1-dev \
    libz-dev \
    pkg-config \
    zip
    ```

=== "Mac"

    ```console
    brew install \
    cmake \
    libidn \
    libsodium
    ```

## Setup

### Configure the Postgres user

`psql` tries to connect to the Postgres server using the same username as your system user.

=== "Debian / Ubuntu"

    ```console
    # For installing createuser
    sudo apt install postgresql-client-common

    sudo su - postgres
    createuser -s -r your_system_username
    ```

=== "Mac"

    First, check whether Postgres is running, e.g.

    ```console
    brew services
    ```

### Configure the build environment

The following settings are required to build gem native extensions.

=== "Mac"

    ```console
    bundle config set --global build.idn-ruby --with-idn-dir=$(brew --prefix libidn)
    ```

### Install integration dependencies

This project can be used to set up all services, and run tests against all of them.

```console
cd integration
bundle install
```

### Install each service's dependencies

```console
bundle exec rake bundle:install
```

Carefully check the output for error messages (e.g. libraries still missing).

### Configure S3

=== "Debian / Ubuntu"

    Run `rake s3:configure` in integration to set up all necessary buckets and configure their policies.

    Make sure minio is running when executing this rake task. If your minio server is running at another endpoint or with different than the default credentials, adapt `~/.xikolo.development.yml` accordingly.

=== "Mac"

    Adopt the `~/.xikolo.development.yml` (copy from `xikolo/integration/features/support/lib/xikolo.development.yml`) and try the minio default key and secret: set both to `minioadmin`.

    Run `rake s3:configure` in integration to set up all needed buckets and configure their needed policies.

    If the rake task `rake s3:configure` does not proceed, try the following:

    - `brew services list` shows that the config is loaded from something like `/Users/<username>/Library/LaunchAgents/homebrew.mxcl.minio.plist`. Inspecting this file reveals that it executes minio by running `/usr/local/opt/minio/bin/minio server --config-dir=/usr/local/etc/minio --address=:9000 /usr/local/var/minio`.
    - To get the secret and access key printed on the shell, shut down the service and run this command once manually. After you copied the keys to the Xikolo config file, you can use minio as a service again.

### Set up databases and other backing services

This command will create databases and database tables as well as queues and exchanges in RabbitMQ and finally set up some example data for development purposes.

```console
bundle exec rake reset
```

### Install and compile frontend dependencies

In `integration/`, run the following command to build all assets:

```console
bundle exec rake assets:build
```

Otherwise, you can run `make` directly:

```console
make assets
```

This is the default target and builds all assets: Sprockets and Webpack.
This target can be customized using `RAILS_ENV` and `BRAND`.

If needed, add a `RAILS_ENV` or `BRAND`, such as:

```console
RAILS_ENV=production BRAND=brandname make assets
```

### Configure EditorConfig support

EditorConfig is a standard for some generic auto-formatting options supported by many IDEs.

!!! tip

    Check <https://editorconfig.org/> for your IDE's built-in support. If not available, please install the corresponding add-on / editor plug-in.

### Prevent push to master

Any push command which operates on the master branch will require confirmation.

!!! note

    1. Copy the snippet below to `.git/hooks/pre-push`
    2. Make the hook executable: `chmod +x .git/hooks/pre-push`

    ```bash
    #!/bin/bash
    protected_branch='master'
    current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
    if [ $protected_branch = $current_branch ]
    then
        read -p "You're about to push master, is that what you intended? [y|n] " -n 1 -r < /dev/tty
        echo
        if echo $REPLY | grep -E '^[Yy]$' > /dev/null
        then
            exit 0 # push will execute
        fi
        exit 1 # push will not execute
    else
        exit 0 # push will execute
    fi
    ```

    Taken from <https://ghost.org/blog/prevent-master-push/>.

### Lint before commit

A pre-commit hook should be automatically installed through `husky` when running `yarn install`. The hook will run several formatting checks and auto-fixes before a commit gets created.

See `lint-staged` rules in `package.json` for applied commands.

### Git commit message template

You can add a git commit message template to help you always have the right format.

Create a `commit-template.txt` file wherever you like.

Add this to the file:

```text
# Use this format for the message header:
# <type>[optional scope]: <subject>
# optional scopes are bound to our services e.g.
# course, account, lanalytics and so on
#| <----- Type Maximum 50 Characters here -----> |

# The commit message body should contain the what and why, starting with a blank line
# For more information, see our guidelines: https://xikolo.pages.xikolo.de/web/development/workflows/review/#commits
#| <---- Try To Limit Each Line to a Maximum Of 70 Characters -----> |


```

Run the following command to set it up.

```console
git config --global commit.template <filepath/commit-template.txt>
```

### Set up your local dev tooling

There are multiple ways to work with your local copy of Xikolo. These tutorials provide hints for a few of them:

- [Install overmind](install_overmind.md) on Linux
- [Configure RubyMine](configure_rubymine.md)
- Use Docker Desktop for background services (Postgres, Minio, Redis, RabbitMQ)

## Starting the project

### Overmind

!!! info

    Xikolo (and its services) is managed in a mono-repository located in the openHPI GitLab, where you can also find the project README. You can use `overmind` with the command line in the project directory as follows:

=== "Debian / Ubuntu"

    See [installation guide](./install_overmind.md)

=== "Mac"

    ```console
    brew install overmind
    ```

The 3 most important services you will always need:

```console
overmind start -l account,course,web
```

Whenever you need additional services, you can add it to this list. When you don't know which services you need, you'll get an error message with the specific port. Just take a look at the 'Procfile'. An overview of all ports is available in `config/services.yml`.

```console
overmind start -l pinboard,collabspace,lti,account,course,news,web,video,quiz
```

Start the project with a different brand than default:

```console
BRAND=your_brand overmind start -l account,course,web
```

!!! note

    Make sure to also set the `brand` and `site_name` options to the brand in the config, e.g. in your `xikolo.development.yml`.

If you have done everything correctly and installed all the necessary tools, you should see the Xikolo platform at [http://localhost:3000](http://localhost:3000).

### External Services with Docker

All necessary external services (PostgreSQL RabbitMQ, Redis, Minio) can be provisioned via Docker using the included `docker-compose.yml`. Initialize and start the defined containers:

```console
docker-compose up
```

The database URL for Xikolo apps must then be set as an environment variable before executing any utility or application with database access, e.g.

```console
export DATABASE_URL=postgresql://localhost:5432
bundle exec rake db:prepare
bundle exec rails s
```

To run overmind with the docker-based databases, load the specific `.env.docker` file:

```console
OVERMIND_ENV=.env.docker overmind start
```

For many IDEs providing run configurations, you can set the environment variable in the IDE settings or the run configurations, e.g. in RubyMine.

## Locales

The project uses `i18n` for internationalization (i.e., localization of content), making these locales accessible to the frontend application using the `i18n-js` gem.
This gem exports the locales into JSON format and stores them in `tmp/cache/xikolo/i18n` for each brand (configured in `./config/i18n`).
These JSON objects are imported in the Webpack code, then, and consumed by the `i18n-js` npm package.

To ensure that the locales are available when Webpack is built and to avoid potential build failures, execute the gem's CLI command (`i18n export`) before executing `yarn run build`. Alternatively, you can simply use `make assets`, which automates all the required steps.

## Seeds

The `rake reset` command that is part of the installation instructions also "seeds" your databases, creating lots of example data (such as courses, course content, and user accounts).

You can run always run again `bundle exec rake reset` in the `integration` folder of your local working environment to put your local copy in a blank, clean state - which can be useful when starting a new task, or trying to reproduce a bug.

Based on the seeds, there will be the following users (besides other less important seed users):

- *Regular user*
  Email: `kevin.cool@example.com`
  Password: `qwe123qwe`

- *Administrator*
  Email: `admin@example.com`
  Password: `administrator`

- *Teacher*
  Email: `tom@example.com`
  Password: `teaching`

## Testing

To run the test suite and make sure you have the necessary drivers, please see the full 'how-to' guide regarding [running tests](../testing/index.md).

## Troubleshooting

- **Apple Silicon:** If you are using a MacBook with an Apple Silicon chip (instead of Intel) be sure to read [this article first](troubleshooting/apple_silicon.md).
- **Known issues:** There is a list of possible problems with solutions for [Mac OS X](troubleshooting/mac_known_issues.md)

## Update this Documentation

If discrepancies are noticed when carrying your local setup, please update this documentation.

- The documentation can be found in the repository here: ``docs/app/development/local_setup/index.md``

To view and edit this documentation locally, you need to install `uv` (if not already installed).
The following commands are to be run from the top-level project directory:

=== "Debian / Ubuntu"

    ```console
    sudo apt install pipx
    pipx install uv
    ```

=== "Mac"

    ```console
    brew install uv
    ```

To run the docs:

```console
uv run mkdocs serve
```
