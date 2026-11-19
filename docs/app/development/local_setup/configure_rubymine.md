# Configure RubyMine

!!! note
    This guide is written for RubyMine but also applies to IntelliJ Ultimate with the Ruby plugins. IntelliJ offers the same options but some might be located in different places.

## Rails

The Rails project root is typically detected automatically. If necessary, right-click on the respective project root and select *Mark as... > Ruby Project Root* from the context menu.

!!! tip
    You might want to set a custom `UNICORN_TIMEOUT` as environment variable to a higher value (e.g., `3600` which represents one hour) to avoid timeouts when debugging the application.

## Background Services

Many of our services (i.e. the Rails apps) use background services (e.g. Sidekiq for asynchronous background jobs and Msgr for asynchronous event communication). Although there are not too many use cases that require the background services to be running when working on code, it is necessary in specific cases.

When working with overmind this is not an issue as these services are started anyway using the Procfile configuration. For RubyMine, this is different, i.e. the background services need to be run explicitly. Of course, this can be done manually via console, but there is also a possibility to run them via RubyMine, which has the advantage to combine them into a Multirun configuration.

## "Mark Directory as"

!!! tip
    You might speed up indexing and improve search results by marking some files and folders with their respective use case or exclude them (e.g. `logs`, `node_modules`, `coverage`)

1. Right-click on the folder to be marked.
2. Select *Mark Directory as...*.
3. Select the most-suitable element from the list.

In order to mark single files, you need to jump over to the project settings and add a comma-separated list of files.
