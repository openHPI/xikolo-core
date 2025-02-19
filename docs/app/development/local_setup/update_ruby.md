# Update RVM and Ruby

This guide will assist you when upgrading the Ruby version of `xikolo` services.
Please commit your changes to the corresponding repository and open a merge request.
The focus of this guide is on preparing the application to a new Ruby version, it does not cover the deployment.

## Local setup (individually)

The following changes need to be performed by each developer individually to get ready for the new Ruby version.

### Update RVM

Using the newest RVM version might help prevent issues with installing Ruby. See
the [change log](https://github.com/rvm/rvm/blob/master/CHANGELOG.md) for more details and recent releases.

```shell
rvm get stable
```

### Update Ruby

Switching to a new Ruby version requires the installation of the corresponding Ruby binaries and preparing all gems.
While RVM will take care of installing Ruby, two approaches are available for gems already installed in a previous Ruby
version:

1. Clean installation of all gems

    Using a clean installation of all gems is the safest approach. It will ensure that all gems are compatible with the new Ruby version. However, it will also take longer to complete.
    This approach is recommended when upgrading to a new major Ruby version.

    The following commands will install all gems from scratch, in accordance with the [local setup](./index.md) guide.
    First, the newest Ruby version is installed, followed by the installation of the newest RubyGems version. Finally, bundler is installed to be used in accordance with the rake tasks in `integration`.

    ```shell
    rvm install 3.4.2
    gem update --system
    gem install bundler

    # Switch to web/integration
    bundle install
    bundle exec rake bundle:install
    ```

2. Migrating existing gems

    Using an existing installation of all gems is the fastest approach. It will first install the binaries of the new Ruby version and then move all existing gems to the new Ruby version.
    The upgrade process might take a while to complete and requires multiple confirmations. However, it might cause issues when upgrading to a new major Ruby version.
    Therefore, this approach is only recommended when upgrading to a new minor Ruby version. Finally, the RubyGems version is also updated to the newest version.

    ```shell
    # Syntax: rvm upgrade <old ruby> <new ruby>
    # Get existing ruby versions with `rvm list`
    rvm upgrade 3.3.6 3.4.2
    gem update --system
    ```

## Code changes (committed)

The following changes are only performed once and need to be committed to the repository.

### Update `.ruby-version`

RVM (and other tools) use the `.ruby-version` file to determine the Ruby version to use.
Therefore, the file needs to be updated to the new Ruby version.

### Update `Gemfile` and `Gemfile.lock`

The `Gemfile` and `Gemfile.lock` files need to be updated to the new Ruby version.

1. `Gemfile`

    The `Gemfile` file needs to be updated to the new Ruby version, where the `ruby` line specifies the Ruby version to use.
    For patch versions, this line should not be touched, as our production versions shall be upgraded independently of the patch version specified in the `Gemfile`.

    ```ruby
    # Gemfile
    ruby '~> 3.4.0'
    ```

2. `Gemfile.lock`

    The `Gemfile.lock` file needs to be updated to the new Ruby and the new RubyGems version.
    Both changes are performed through the following commands and the `Gemfile.lock` should not be changed manually.

    1. Ruby version

        The `RUBY VERSION` line specifies the Ruby version to use.

        ```ruby
        # Gemfile.lock
        RUBY VERSION
           ruby 3.4.2p28
        ```

        The `RUBY VERSION` is updated with the following command:

        ```shell
        bundle update --ruby
        ```

    2. Bundler version

        The `BUNDLED WITH` line specifies the Bundler version that generated the lock file and that should be used to install gems.

        ```ruby
        # Gemfile.lock
        BUNDLED WITH
           2.6.3
        ```

        The `RUBY VERSION` is updated with the following command:

         ```shell
         bundle update --bundler
         ```

!!! tip

    The changes to the `Gemfile` and `Gemfile.lock` are required for each service, and `integration/`. You can use `find` to run a command for each Gemfile that exists in the repository:

    ```shell
    find . -name Gemfile -execdir bundle update --ruby \;
    ```

    And for bundler:

    ```shell
    find . -name Gemfile -execdir bundle update --bundler \;
    ```

### Update `.gitlab-ci.yml`

The `.gitlab-ci.yml` file needs to be updated to the new Ruby version. The `image` line specifies the Docker image to use for the respective job in the CI pipeline.

For example:

```yaml
# .gitlab-ci.yml
image: ruby:3.4.2-slim
```

!!! note

    Renovate will include this in its maintenance merge requests, and will bump this together with other image digests, such as the Ruby base image in Dockerfiles.

### Documentation

Once you changed all versions, please remember to update the
[local setup](./index.md) guide to reflect the new Ruby version (e.g., in the `rvm install` command).
