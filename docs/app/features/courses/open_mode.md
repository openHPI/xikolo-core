# Open mode

## General idea

The open mode provides learners with an initial glimpse of targeted video content, much like a preview before a film.
This approach aims to engage learners by offering a sneak peek into the subject matter, cultivating anticipation, and forging a connection between learners and the material.
It also contributes to SEO, as the open mode videos can be indexed and found by Google's search algorithms.

## Behaviour

In order to promote certain courses with a video item in open mode the following prerequisites need to be fulfilled.

  1. Global activation of open mode through the config settings.
  2. The course must have an video item where open mode is set.
  3. The course should not be hidden or restricted to invite_only access.

The open mode is designed for anonymous users or those who are logged in but not enrolled.
They will be directed to the first video item in open mode.

## Usage

To utilize the open mode feature, you must activate it in the configuration by setting "enabled" to true. The "default_value" will establish its value for newly created videos.

  ```ruby
  open_mode:
    enabled: false
    default_value: false
  ```
