<!-- markdownlint-disable-file MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- nothing

### Changed

- nothing

### Removed

- nothing

## 1.5.2 - 2023-11-09

### Changed

- `Xikolo::S3.copy_to`: Take optional content_disposition param

## 1.5.1 - 2020-07-20

### Fixed

- Seahorse adapter: Stop mutating request headers

## 1.5.0 - 2020-07-16

### Added

- When `mnemosyne-ruby` is installed, HTTP requests to S3 will now be traced

## 1.4.0 - 2019-04-10

### Added

- New method `Aws::S3::Object#unique_sanitized_name` for handling our most common use case

## 1.0.0 - 2018-08-22

Initial release
