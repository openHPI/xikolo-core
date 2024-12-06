# The review process

Now that you put your code out in the open, it is time for other team members to check out what you did, ask questions, and propose improvements. We do this to ensure good quality - many eyes catch more bugs, and different people have different perspectives, which often leads to better ideas and solutions.

Please don't take the feedback on your code personally, no one aims to offend colleagues.
Rather take it as an opportunity to learn and improve your skills.

To indicate the start of the review process in the corresponding ticket, please update the ticket status to *In Review*.

## Invite reviewers

Do good work and talk about it! There are multiple levels of escalation to let others know about your new MR:

1. Many developers already watch our repositories, so they will get (email) notifications about new MRs automatically.
2. Ensure you selected a relevant milestone (if applicable) so that your MR appears in [this handy list](https://lab.xikolo.de/groups/xikolo/-/merge_requests?scope=all&state=opened&milestone_title=%23started).
3. Additionally, keep track that your MR is up-to-date:
    - When the next working phase starts and your MR is part of it, please don't forget to adjust the milestone in GitLab.
    - If the milestone does not yet exist, you can create it yourself for the Xikolo group in GitLab.
4. You can and should tag developers in GitLab that may be interested in your MR or have knowledge in this area.
5. If (and only if!) a deadline is coming closer or your change is [very urgent / critical](https://google.github.io/eng-practices/review/emergencies.html#what), you may ask for reviews in the code review chat channel.

    !!! tip

        **Please do so sparingly**. Your colleagues probably get notifications already and are probably working on valuable tasks themselves.
        Are you sure your work is more important / warrants an interruption?

!!! info "Tag groups"

    You can always tag the **@core** group to notify the core developer team.
    To receive feedback specifically on design changes, notify the **@design** group.

## Incorporating feedback

Once you have your first reviews coming in, engage with the comments, follow up with questions and improvements, and try to get the discussions resolved.
You don't have to follow every suggestion - try to explain why you made a certain choice.
Sometimes, reviews can expose problems, or be overwhelming for other reasons.

Again, don't take it personally - you are not your work, and commenters generally try to propose improvements for the better of the project.

When making changes to the code, try to add additional commits instead of amending existing commits to ease the review process. With (small) new commits on top of your original changes, your additional changes can be reviewed and understood more quickly.
They can still be squashed before merging the MR.

!!! warning "Do not push every single change you made based on the discussion to your feature branch!"

    This starts an unnecessary number of TeamCity builds and leads to many more email notifications.
    Instead, make the changes in individual commits locally and push them to your feature branch at once.

Once a discussion item has been addressed (e.g., it has been resolved or a follow-up task has been created), resolve it so others can better track the state of the MR. Ping a person if there has been no reaction to a question or discussion for two or more days.

Additionally, if you are not sure if a discussion item has been properly addressed, ask someone to confirm that. Do not simply resolve discussion threads to speed up the process.

If it turns out that the chosen implementation approach was wrong or there is a change in the scope of your MR, try to address it in one of the meetings (preferably in the Dev Stand-Up meeting) and decide how to proceed.
It is completely fine to close a merge request, put it back in *WIP*, split it up in multiple MRs, or even go back to the drawing board. The important point here is not to block reviewing and development capacities.

## Tips for reviewing

If you hope for your code to be reviewed, pay it forward by reviewing others' merge requests!
Make this a regular habit, so that we move forward quickly, and work in progress does not get stuck in the queue.

!!! success "Make it a habit to review another open MR after opening one yourself!"

    This maintains a healthy balance.
    If possible, schedule a dedicated slot for reviewing other MRs every day.
    [This is an overview of all open MRs](https://lab.xikolo.de/groups/xikolo/-/merge_requests).
    You can also [search for the current milestone](https://lab.xikolo.de/groups/xikolo/-/merge_requests?scope=all&state=opened&milestone_title=%23started) to focus on getting current tasks done.

Reviews are not only a requirement for getting code merged (and therefore moving forward), but they are also a great chance to distribute knowledge and grow! Don't be afraid to take a look at code you haven't touched before.

### High level

As a starting point for your review, you can check for code functionality.
Check out the branch and try the changes locally to make sure they work as expected and to catch any issues.
Check code structure and readability to ensure that it follows best practices, is easy to understand, and maintainable in the long run.
Have a look at the test coverage and check for a passing pipeline.
Documentation should be complete, accurate, and up-to-date.

### Best practices

The following tips have helped us provide better code reviews:

- Be kind.
- Don't be afraid to ask if you don't know or understand something. Questions open up opportunities to share knowledge. Having them (and the answers) written out can also be a great resource.
- Prefer asking questions and making suggestions over demanding changes.
- Try multiple passes over the code.
  - First, focus on the big picture. Would you expect changes in more or fewer files? Which parts of the system are touched and why?
  - Then, look at the nitty-gritty details. Does the code follow conventions? Is it readable? Are concerns separated clearly?
- Point out nitpicks (e.g. a typo, inconsistent style) in only one place, and mention the chance of multiple occurrences. The author of the MR should be able to take care of all the other occurrences.
- When applicable, try reviewing commit by commit. This can help to understand the changes that were made when they would otherwise be too large / intermingled.

Others, [e.g. Google](https://google.github.io/eng-practices/review/), have written up even more valuable tips.

!!! success "Step by step"

    - Set your ticket to *"In Review"* state.
    - Add the relevant milestone to mark the MR as part of the current working phase (if applicable).
    - Invite reviewers:
        - Most likely, developers will already get a notification about your new MR automatically.
        - Tag developers from specific groups or with expert knowledge.
        - Ask for reviews in the Code Review channel if the ticket is urgent.

## Approving a merge request

When you have reviewed a merge request and added your comments, and no further code changes are required, approve it.
We use the [GitLab approval](https://docs.gitlab.com/ee/user/project/merge_requests/approvals/) feature which, however, does not technically block a merge request.
Please, always wait for the required number of approvals (see below).

!!! warning

    If a merge request was created collaboratively in a team, e.g. with pair or mob programming, the members of the team should not approve the MR, since this contradicts the 6-eyes-principle we want to implement here.
    It's still fine to vote up for the developers in the team who did not have the lead.

### Find the right balance

- Don't be too favorable with your approval, as merging faulty code can cause problems on production or is harder to maintain. But it's not the end of the world if it happens. It's important to learn from mistakes / errors.
- If you are sure that the changes are good, do not hesitate as approving is a way of unblocking the development process and help your fellow developers.
- Please also remove your approval once any of the criteria mentioned above change, e.g. because of incorporating change requests into the MR.

In addition to the approval, you can use different emojis to indicate the overall feedback in more detail:

#### :thumbsup: Upvote

This reflects the approval as follows:
I have reviewed the MR thoroughly and it is complete (from my point of view) and ready to be merged. It contains all necessary changes, translations, tests, ..., i.e. it adheres to our [Definition of Done](https://confluence.hpi.de/display/XIKOLO/Definition+of+Done).
If there are open discussions, these are only cosmetic changes or suggestions, that should not block this MR from being merged.

!!! info

    If you notice an ongoing discussion / larger changes on an already upvoted MR, reconsider your upvote regularly.

#### :thumbup_tone1: Partial upvote

I have reviewed the MR thoroughly, but I'm not an expert in this domain / area or comfortable with the used programming language so I cannot entirely confirm the correctness of the changes.

!!! info

    Add a comment explaining your thoughts / doubts and raise questions or concerns if necessary.
    Do not use this if you only partially reviewed the MR. In this case, rather comment on the MR to give feedback where possible.

#### :art: Design upvote

I have reviewed the MR from a design (UI/UX) perspective.
The UI/UX changes look reasonable and match our UI/UX standards.
(If applicable) They also adhere to our decisions made in the UI/UX meeting.

!!! info

    Only use this kind of upvote, when you are part of the @design group or participate in the [UI/UX meeting](https://confluence.hpi.de/pages/viewpage.action?pageId=77300803).

## Merge

A merge request is ready to be merged when:

- there are two approvals by other developers,
- there are no downvotes by other developers,
- the build pipeline is green,
- the commit history is clean (unrelated changes should be separated in atomic commits, related changes should be squashed, and
- all discussions have been resolved.

When all of these can be checked off, the merge request is ready to be merged. Once your merge request reaches that state, **feel free to press the green button** - it's a great feeling! You should feel as the owner of your task and the entire task of getting it to production - this includes updating tickets, merging merge requests, and deploying.

!!! warning "Don't forget!"

    Delete the source branch after merging, to keep the repository clean!
    GitLab offers a handy checkbox to do so when creating a merge request, and later when merging, but there will also be a button after merging.

Unless you're working on a very urgent bug fix, it can be nice to leave the merge request open for at least 24 hours, so that even more developers have a chance to chime in / see your changes.
We believe this strikes a nice balance between development velocity and quality.
In short: Give others (and yourself!) a chance to sleep over it.

!!! info "Ship / Show / Ask"

    Not all branches are created equal.
    We are trying to adopt the [Ship / Show / Ask](https://martinfowler.com/articles/ship-show-ask.html) strategy:

    When you own an area of the codebase, or a change is trivial, you may also push code ("Ship") to the master branch directly.
    Use this power cautiously! If you feel unsure, or would like to wait for a green build, or would like to use the opportunity to document things with your teammates, a "Show" MR is a great middle ground:
    You can merge such an MR once the build is green, without having to wait for the approval.
