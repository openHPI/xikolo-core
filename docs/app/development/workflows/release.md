# Release Workflow

To create a new release, follow these steps:

1. Announce in rollout channel and choose a nice gif to celebrate it
2. Choose a commit to release (usually the latest on main)
3. Press release button, the commit will be tagged automatically and a new pipeline will be triggered in the deployment repo
4. Monitor production closely e.g. on Sentry
5. Collect user facing changes (Release Notes) in the commit history
6. Write release notes in the [release notes repository](https://gitlab.hpi.de/openhpi/xikolo/release-notes) and create a merge request.
