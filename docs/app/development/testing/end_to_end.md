# End-to-end (E2E) tests

## Running end-to-end tests

Our end-to-end test scenarios test the entire application stack through a browser, as it would be done by a user. These scenarios reflect real-world requirements and ensure that all critical functionality works correctly from the perspective of a user.

!!! info

    We used to talk about these as "integration tests" (and the file directory still documents this old naming). As that terminology usually refers to all tests that verify the combination of multiple system components, we try to use the more precise "end-to-end tests" terminology.

### Prerequisites

Before you can run end-to-end tests, [Minio server](https://www.minio.io/downloads.html#download-server) needs to be installed to provide a local S3 API for the end-to-end tests. Install Minio and make it available on your system `PATH`: `minio version` should be executable and return minio's version. The test setup will automatically launch and configure `minio` for the test execution.

### Setup / Updating

!!! info

    Every command below needs to be run in the `integration` directory.

When you have not run end-to-end tests for a while, you should update the test environment to the latest version:

```shell
# Build assets
RAILS_ENV=production bundle exec rake assets:build

# Create and migrate databases
RAILS_ENV=integration bundle exec rake db:prepare

# Migrate permissions
RAILS_ENV=integration bundle exec rake permissions:load
```

### Run test scenarios

Running end-to-end tests is quite slow, as all application services has to be started. Depending on your needs, you might want to switch between the different modes of operation supported by [Gurke](https://github.com/jgraichen/gurke) (the test runner we use for end-to-end tests).

#### Alternative 1: One-off test runs

The easiest way to run a test (e.g. to reproduce a test failure on CI servers) is the following:

```shell
bundle exec gurke features/my_feature.feature
```

If you do not want to rely on the default browser (Chrome), you can choose a different browser using an environment variable:

```shell
BROWSER=firefox bundle exec gurke features/my_feature.feature
```

!!! tip

    If you do not want to type this out every time, you can set a default browser for your local machine by creating a `.env` file with the desired environment variables (e.g. `BROWSER=firefox`). This can still be overwritten for single executions in the command line.

You probably do not want to run all tests in our test suite. Pass a file or directory (or multiple ones) as arguments to `gurke` to select which tests you want to run:

=== "One scenario"

    ```shell
    bundle exec gurke features/my_feature.feature:10
    ```

=== "All scenarios in given files/folders"

    ```shell
    bundle exec gurke features/courses features/items features/special.feature
    ```

=== "All scenarios"

    ```shell
    bundle exec gurke
    ```

#### Alternative 2: Test server

Instead of starting the application services every time you want to run tests, you can also keep the services running in one console window and then run tests against them in another. You can use the following command to start a background server and a browser instance.

```shell
BROWSER=firefox bundle exec gurke --drb-server
```

The previous command starts the application services. With the following command, you can actually run tests against them.

```shell
bundle exec gurke --drb features/my_feature.feature
```

Just like before, you can also run all tests or just one scenario in a given file. Just do not forget the `--drb` flag!

#### Additional options

##### Snapped Firefox

If you are using Ubuntu 22.04+, you need to add `SNAP=1` to make Capybara to use the snapped Firefox that comes with your OS.
Otherwise, Capybara tries to start the snap binary, causing a "binary is not a Firefox executable" error.

##### Non-headless mode

Per default, the E2E tests are run in headless mode (i.e. no visual browser window). If you want to see the browser window, set `HEADLESS=0` when starting the test server.

##### Slow motion mode

If you want to visually debug a test, you can set `SLOW=1` (use higher values to slow down even further). The slow motion mode will sleep a little bit before every Capybara
action, so that you can actually follow its steps.

### Debugging test failures

If a test fails because of errors from backend services, check the `log/integration.log` in the respective service(s). To see more information in those log files, you can use `Rails.logger.debug()`.
