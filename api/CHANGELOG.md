<!-- markdownlint-disable-file MD024 -->

# Changelog

All notable API endpoint changes (especially breaking ones) will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

### Deprecated

### Removed

## [4.10] - 2024-03-14

### Added

- `questions` type:
  - New `referenceLink` attribute, which points to the corresponding `Course::Item` of the selftest question

## [4.9] - 2024-02-15

### Removed

- `courses` type:
  - `objectives` relationship
  - `objectives_user_statuses` relationship
- `learning-units` endpoint without replacement
- `objectives` endpoint without replacement
- `objectives-user-statuses` endpoint without replacement
- `objective-progresses` endpoint without replacement
- `user-objectives` endpoint without replacement
- `qcalerts` endpoint without replacement
- `statistics` type:
  - `qc_alerts` for the course and platform dashboard

## [4.8] - 2024-02-15

### Deprecated

- `classifiers` type:
  - Deprecate `description` attribute, always returning `nil`
- `channels` type:
  - Deprecate `stage_stream` attribute. Support for channel videos has been removed, use images instead (`stage_image_url`).
  - Deprecate `color` attribute. Use any other color, e.g. the primary color, for styling.

### Removed

- `course-statistics` endpoint without replacement
- `subtitle-cues` type:
  - `subtitle-track` relationship, since the generated link was invalid

## [4.7] - 2022-11-30

### Added

- `courses` type:
  - New `show_on_list` attribute, which indicates whether the course should appear on the course list
- `questions` type:
  - New `eligible_for_recap` attribute, which indicates whether the question can be used in a quiz recap

## [4.6] - 2022-07-20

### Added

- `platform-events` type:
  - New `preview_html` attribute with pre-rendered and sanitized (!) HTML

### Removed

- `payments` and `products` endpoints without replacement
- `platform-events` type:
  - `preview` attribute, which contained potentially unsafe Markdown

## [4.5] - 2022-01-07

### Added

- New `features` endpoint:
  - New `features` attribute
- New `course-features` endpoint:
  - New `features` attribute
- New `experiment-assignments` endpoint:
  - New `identifier` attribute
  - New `course` relationship

## [4.4] - 2021-11-10

### Added

- New `clusters` endpoint:
  - New `visible` attribute
  - New `title` attribute

### Deprecated

- `course-items` type:
  - The `icon` attribute will return different icon types for the items

## [4.3] - 2021-05-03

### Added

- `courses` type:
  - New `learning_goals` attribute
  - New `target_groups` attribute

## [4.2] - 2020-08-11

### Added

- New `last-visits` endpoint:
  - New `visit_date` attribute
  - New `item` relationship
- `courses` type:
  - New `last_visit` relationship

## [4.1] - 2020-06-22

### Added

- `courses` type:
  - New `images` attribute

## [4.0] - 2020-05-04

### Removed

- `videos` type:
  - `title` attribute (use `title` from `course-items`)
- `channels` type:
  - `name` attribute (use `title`)
  - `slug` attribute (use `id`)
- `course-statistics` type:
  - `course_name` attribute (use `course_code`)
  - `certificates` attribute (use `roa_count`)
- `quizzes` type:
  - `max_points` attribute (use `max_points` from `course-items`)
- `user-profile` type:
  - `first_name` and `last_name` attribute (use `full_name`)
- `course-progresses` type:
  - `section-progresses` relation (use `section_progresses`)
- `course-progresses` type:
  - `section-progresses` relation (use `course_progress`)

## [3.9] - 2020-04-02

### Added

- `user-profile` type:
  - New `full_name` attribute

### Deprecated

- The `first_name` and `last_name` attributes of the `profile` endpoint will be removed in version 4.0. Use the `full_name` field instead.

## [3.8] - 2019-08-29

### Deprecated

- The `payments` and `products` endpoint are deprecated and will be removed without replacement.
  - Reason: Payment will soon be handled by external shops (that will sell vouchers) only.

## [3.7] - 2018-12-14

### Added

- `lti-exercises` type:
  - New `exercise_type` attribute

## [3.6] - 2018-10-02

### Added

- `peer-assessments` type:
  - New `instructions` attribute
  - New `type` attribute
- `lti-exercises` type:
  - New `launch_url` attribute
- `items` type:
  - New `max_points` attribute
- `quizzes` type:
  - Deprecate `max_points` attribute
- `videos` type:
  - Deprecate `title` attribute

## [3.5] - 2018-04-09

### Added

- `channels` type:
  - New `title` attribute
  - Deprecate `name` attribute

## [3.4] - 2018-03-19

### Added

- `channels` type:
  - New `mobile_image_url` attribute

## [3.3] - 2018-03-12

### Added

- `channels` type:
  - New `logo_url` attribute
  - New `description` attribute (respects `Accept-Language` header)
  - New `stage_image_url` attribute
  - New `stage_statement` attribute
  - New `stage_stream` attribute

## [3.2] - 2018-02-27

### Added

- `courses` type:
  - New `teaser_stream` attribute

## [3.1] - 2017-12-18

### Added

- `channels` type:
  - New `position` attribute

## [3.0] - 2017-12-07

### Changed

- `enrollments` type:
  - The `certificates` attribute is still a hash, but the values are now either strings (a URL pointing to the downloadable certificate) or `null`, when the corresponding certificate is not available to the user.
    (Previously, they were booleans.)
- `videos` type:
  - The `subtitles` attribute now is an array of hashes (each with the keys `language`, `created_by_machine`, and `vtt_url`) instead of a hash keyed by language identifier.

### Removed

- The `/news-articles` endpoint (and the corresponding `news-articles` type) has been completely removed.
  Use the `/announcements` endpoint (with the type `announcements`) instead.
- `course-items` type:
  - The `type` attribute is now gone.
    Use the `content_type` attribute instead, which has been available since version 2.
- `course-statistics` type:
  - The following attributes have been completely removed (they have been deprecated for a while in version 2):
    - `questions`: Use `threads` instead
    - `questions_last_day`: Use `threads_last_day` instead
    - `answers`: Use `posts` instead
    - `answers_last_day`: Use `posts_last_day` instead
    - `comments_on_questions`: Use `posts` instead
    - `comments_on_questions_last_day`: Use `posts_last_day` instead
    - `comments_on_answers`: Use `posts` instead
    - `comments_on_answers_last_day`: Use `posts_last_day` instead
    - `questions_in_learning_rooms`: Use `threads_in_collab_spaces` instead
    - `questions_last_day_in_learning_rooms`: Use `threads_last_day_in_collab_spaces` instead
    - `answers_in_learning_rooms`: Use `posts_in_collab_spaces` instead
    - `answers_last_day_in_learning_rooms`: Use `posts_last_day_in_collab_spaces` instead
    - `comments_on_questions_in_learning_rooms`: Use `posts_in_collab_spaces` instead
    - `comments_on_questions_last_day_in_learning_rooms`: Use `posts_last_day_in_collab_spaces` instead
    - `comments_on_answers_in_learning_rooms`: Use `posts_in_collab_spaces` instead
    - `comments_on_answers_last_day_in_learning_rooms`: Use `posts_last_day_in_collab_spaces` instead
- `enrollments` type:
  - The attributes `visits` and `points` were removed.
    This information can be gleaned from the course's `course-progress` resource.
