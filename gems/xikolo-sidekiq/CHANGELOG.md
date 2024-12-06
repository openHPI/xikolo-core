<!-- markdownlint-disable-file MD024 -->

# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/) and [Keep a Changelog](https://keepachangelog.com/).

## Unreleased

---

### New

### Changes

### Fixes

### Breaks

## 4.0.0 - (2023-06-08)

---

### Changes

- Upgrade sidekiq to 7.x
- Update sidekiq-cron to 1.4

### Breaks

- Redis: Removed `reconnect_delay_max` and `reconnect_delay`, precise sleep durations can be passed to `reconnect_attempts`.
- Sidekiq will raise an exception if JSON-unsafe arguments are passed to `perform_async`.
- Minimal dependencies ruby (>= 2.7), redis (>= 6.2), rails (>= 6.0)

## 3.2.0 - (2022-02-09)

### Changes

- Drop monkey-patch for `Sidekiq::Client` as the fix has been applied upstream

## 3.1.0 - (2021-09-16)

### New

- Monkey-patch `Sidekiq::Client` to retry on `Redis::CommandError` when pushing jobs to Redis

## 3.0.0 - (2019-09-20)

### Changes

- Upgrade sidekiq to 6.x

### Breaks

- Drop redis-namespace integration: `config/sidekiq_redis.yml` need to be adjusted, take a look at the README.
- Minimal dependencies ruby (>= 2.5), redis (>= 4.0), rails (>= 5.0)

## 2.0.0 - (2019-07-02)

### Changes

- Update sidekiq to 5
- Update sidekiq-cron to 1.1
- Update and cleanup gem development tooling

## 1.0.1 - (2018-07-24)

### Changes

- Only configure cronjobs when Sidekiq was started
