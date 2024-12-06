# Emails

The email services need to have a (custom) layout specified.
Otherwise, they will fallback to a default template which is not meant to be seen by the user.

If the brand makes use of email features, add a folder in `services/news/brand/<name>` and `services/notification/brand/<name>`.
In this folder, custom templates are located in the `assets/views/layouts`.
Have a look at `services/[news|notifications]/views/layouts` to see which need to be replaced.
There you may also include custom a stylesheet in `assets/stylesheets`, that is named `foundation_<name>.scss`.
