# What does this change?

_First, briefly describe what this merge request does._

_Then, describe the changes in more detail._
_Make sure potential reviewers have enough information to quickly dive in and understand the changes. Check our [documentation](<https://xikolo.pages.xikolo.de/web/development/workflows/review/>) for more details._

## Decisions / Choices I made

This text should provide background information on the changes you did. A great merge request answers at least the following question:

- Which architectural or implementation decisions did you make? And why?

Remember: The more information you give other developers, the easier it is for them to understand and review the code, and the more helpful their review will ultimately be.

For more context, you should also link to related merge requests as well as corresponding issues on the bug tracker.

Finally, feel free to @tag other developers to ask them to review your work. Always start with reviewing your own MR first. You can do so by scrolling down and checking the "Changes" tab.

## Release Notes

```text
- Add a bullet point for customer-facing release notes as described in https://lab.xikolo.de/xikolo/release-notes or "N/A"
```

## Checklist

- [ ] Your branch has no merge conflicts with master (otherwise, please rebase)
- [ ] [All related commits are squashed together](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#Squashing-Commits)
- [ ] Documentation has been added (Code, [Documentation](https://fictional-doodle-ggey6ov.pages.github.io/), [Teaching Team Guidelines](https://github.com/openHPI/TeachingTeamGuidelines))
- For database changes:
  - [ ] Schema is up-to-date with migrations
  - [ ] Seed data is extended / updated
