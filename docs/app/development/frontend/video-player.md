# Video player

## Development

Any development takes now place in the [GitHub repository](https://github.com/openHPI/xikolo-video-player).
Make sure to read the [contribution guidelines](https://github.com/openHPI/xikolo-video-player/blob/main/CONTRIBUTING.md) beforehand.

## Create a new release

To create a new release on GitHub is not difficult.
Have a look at the [official documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

To prepare the release, you will have to:

1. Bump the version according to [semantic versioning](https://docs.npmjs.com/about-semantic-versioning) in `package.json` and `package-lock.json` (if not already done in another commit)
2. Rebase the `main` branch with the current `dev`
3. Target the `main` branch for release

In the repo, there is an action set up that automatically publishes a package in our [npmjs organization](https://www.npmjs.com/package/@openhpi/xikolo-video-player) when creating a release.
So a release on GitHub is always synchronized with the released npm package.

### Release notes

When creating the release notes from a package release, you may use the "Generate release notes" button.
This will automatically generate a list of all merged PRs with their contributors and a link to the corresponding commit.

Add the label `[Feature]`, `[Maintenance]`, `[Bugfix]` or `[Task]` in front of each generated bullet point and, if applicable, the corresponding ticket number. Example:

```md
- [Feature] Extend public API with current progress (XI-5191) by @developer_1 in #69
- [Bugfix] Double click on any player element triggered full screen by @developer_2 in d564cdf
- [Maintenance] Update dependency @types/vimeo__player to v2.18.0 by @renovate in #66
```

## Restore git history

We used to integrate the video player as a dependency from our [internal GitLab](https://lab.xikolo.de/xikolo/video-player).
As part of open sourcing, we decided to remove the git history in order not to disclose sensitive information.
The history can still be read in the [archived repository](https://lab.xikolo.de/xikolo/video-player).

More convenient for local development is to include the history locally via [`git replace`](https://git-scm.com/book/en/v2/Git-Tools-Replace).
This has to be just set up once.

In a nutshell, it tells git to refer to the [last commit in the GitLab project](https://lab.xikolo.de/xikolo/video-player/-/commit/0b68b95b50f0cb7cf7adc23242b7eb8c35f527d7) every time you have a look at the [first commit on GitHub](https://github.com/openHPI/xikolo-video-player/commit/d73ff6ae4e25bcc164513104af0e52f3b4644501).

1. Add the archived GitLab repo as remote

    Go to where the video-player repository is located in your setup and enter the following command. You can choose any name instead of `origin-gitlab`.

    ```bash
    git remote add origin-gitlab git@lab.xikolo.de:xikolo/video-player.git
    ```

2. Replace the first commit from GitHub with the last on GitLab

    ```bash
    git replace d73ff6ae4e25bcc164513104af0e52f3b4644501 0b68b95b50f0cb7cf7adc23242b7eb8c35f527d7
    ```

3. Previous commit history becomes visible again

    With `git log` you should see the initial GitHub commit replaced by the last on GitLab indicated with `(HEAD -> main, replaced, origin/main)`.
    Following all commits in the GitLab commit history.
