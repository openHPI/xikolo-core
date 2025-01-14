# Local development

This section focuses on all aspects related to the development of the Xikolo platform, including

- the [local setup](local_setup/index.md) of the platform on Unix systems and framework / runtime upgrade guides,
- everything needed to keep the local environment up-to-date (see below),
- details and guidelines for the [frontend implementation](frontend/index.md) and [branding](branding/index.md) of the platform,
- explanations of specific implementation concepts,
- a guide on how to use [database migrations](best_practices/database_migrations.md),
- our [testing best practices](testing/index.md) ,
- the available [monitoring tools](monitoring/index.md),
- and general workflows that apply to our development process, e.g. [code reviews](workflows/review/index.md).

## Staying up-to-date

After working on a specific feature (branch) for a while, some parts of your local system may need updates, e.g. installing new dependencies or running database migrations. When switching back to the main branch, it is therefore advisable to update your local system. You can do so by running the following commands:

```shell
# Pull latest commits:
git pull

# Install latest Ruby dependencies across all services:
cd integration
bundle install
bundle exec rake bundle:install
cd ..

# Install latest frontend dependencies and compile them:
# This is the default target and builds the assets: Sprockets and Webpack.
make assets
# This must be done additionally for each brand you require:
BRAND=brandname make assets

# [Optional] Sometimes, some assets need to be (re-)built only:
# Build Webpack assets only.
make webpack

# Build Sprockets assets only.
make sprockets

# Prepare the database (i.e., run migrations):
bundle exec rake db:prepare
```

Depending on what you have been or are planning on doing, you may skip some of these steps, of course.

## System reset

When you have not updated your local system in a while, or start work on a completely new feature where our development seed data is of help, it is advisable to reset your local environment to its initial state. To do so, run the following command:

```shell hl_lines="2"
cd integration
bundle exec rake reset
```

!!! note

    Make sure that Minio (our recommended local S3 server) is running when you run this command.

!!! danger "This is a complete reset!"

    All local state (PostgreSQL, Redis, RabbitMQ, S3) will be deleted. On the bright side, the system will be re-seeded, so that you can play around with useful example data for many features.
