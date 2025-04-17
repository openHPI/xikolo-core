# Create a merge request (MR)

When you are done with your task - and sometimes before - it is time to collect feedback from your peers. Time to open a merge request.
Once you push new changes on your branch up to the Git server, GitLab will prompt you to open a merge request with these changes (both on the Git command line and the GitLab web interface). Use this link to get started!

!!! info

    When your branch consists of just one commit on top of the target branch, GitLab will use it to pre-fill the merge request form. Writing good commit messages, therefore, pays off, as they answer most of the questions the MR description should answer.
    Additionally, there is a merge request template named "Xikolo" - you can select it in the dropdown next to the MR title. Please fill in this template when creating your merge request.

## Before submitting the MR

A good merge request is crucial for efficient collaboration in software development teams. <br> So, what makes a good merge request?

### Changes

- If the changes become too many, try to slice further.
- Limit the size! The work will be easier for your reviewers, and the [reviews will be far more useful](https://twitter.com/iamdevloper/status/397664295875805184).

### Commits

- Organize changes in separate commits that build on each other.
- Changes should be contained as a unit, to reduce scope.
- Group changes by topic in commits.
- Do not include unrelated changes.

We follow the [conventional commits specification](https://www.conventionalcommits.org/en/v1.0.0/), adapted to our domain. To comply to it, structure each commit
message in the following way (we have a [commit message template](../../local_setup/index.md#git-commit-message-template) to help you with the formatting):

```git
<type>[(optional scope)]: <subject>

[optional body]

[optional footer(s)]
```

The different parts are explained in more detail below, but here’s an example of a commit message to give you an idea:

```git
fix(JS): include dimple as legacy library

We need to attach the dimple constructor to the window object
to use its functions in inline JS.

Resolves XI-6540
```

#### Commit message types

Here is how the *types* we use are defined (some with *type*-specific *scopes* in parentheses):

- `build`: Changes that affect the build system or external dependencies (`docker`, `npm`, `assets`, `S3`)
- `chore`: Routine tasks like running linters manually, updating dependencies etc. (`lint`, `prettier`, `deps`)
- `ci`: Changes to our CI configuration files and scripts
- `docs`: Documentation changes only
- `feat`: A new **user-facing** feature
  - This includes not just platform-users like students and teachers. E.g., when adding seeds for local development is the feature, the developers would be considered as users.
- `fix`: A bug fix including test(s) ensuring the fix
- `perf`: A code change that improves performance
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `style`: Changes that do not affect the meaning of the code (e.g., white-space or formatting)
- `test`: Adding missing tests or correcting existing tests (`e2e`, `features`, `requests`)

#### Commit message scopes (optional)

Add a *scope* to the commit *type* in parentheses to provide additional contextual information. Whenever a change is
specific to a (former) service, you may add that as the scope. More fine-granular *scopes* are also possible,
e.g. `learner_dashboard`. There are some *type*-specific *scopes* (see the list of *types* above).

Whenever a change is more specific to a certain architectural component than to a feature of the platform, those are
also possible as *scopes*: e.g. `assets`, `components`, `jobs`, `lib`, `models`, `operations`, `presenters`, `views`.

When it comes to *scopes* there is not really a right or wrong. To find a fitting *scope*, you can ask yourself:
*When I want to find that commit in a couple of months, what would I search for in the commit history?*.

#### Commit message subject & body

- Separate the subject line from the body with a blank line
- Limit the subject line to 50 characters
- Do not end the subject line with a period
- Use the imperative mood in the subject line
- Wrap the body at 72 characters
- Use the body to explain what and why vs. how
- See [rules of a great commit messages](https://cbea.ms/git-commit/) for explanations

#### Commit message footer

Use the footer, separated from the body with a blank line, to list related tickets, merge requests and co-authors.

```git
(Part of|Fixes|Resolves|Closes|Relates to) X-XXXX
Follow-up for !MR-NUMBER.

Co-authored-by: NAME <NAME@EXAMPLE.COM>
Co-authored-by: ANOTHER-NAME <ANOTHER-NAME@EXAMPLE.COM>"
```

### Merge request description

- Choose a concise (short, but precise) summary line that is prefixed with the corresponding ticket identifier (GitLab will automatically recognize this and link to the ticket).

    !!! info

        - :white_check_mark: Good: `[XI-1234] Upload course videos directly to learners' brains`
        - :x: Bad: `xk/my-branch-name`

- Add a detailed description (use the template!) to highlight the purpose and impact of the changes made
- Shortly explain the idea behind the ticket and who it will affect. This, together with the summary line, should answer the *"What?"* question.
- A link to the ticket is helpful for reviewers to gather additional context (if they want to), but reading the ticket should not be required to understand the merge request.
- Try to draw a bigger picture: What has been done so far? What does this MR build on? What are the required follow-up tasks?
- For UI changes, include screenshots, screencasts, or ideally a link to a staging platform where the feature can be tested.
- In the description, explain your implementation approach and what choices you made. Focus on the *"How?"* and *"Why?"* questions.
- Select the corresponding milestone if the ticket is part of a working phase. This helps reviewers find the MR if they focus on the current tasks.

And finally, **be the first reviewer**! Before you submit the merge request, take a look at the Changes tab to see whether your merge request contains all the changes you intended (and no more). This can often catch low-hanging review fruits before the official review process has started. Already add comments in lines where you have questions to point them out to others.
An MR that does not follow these guidelines may require more effort from both the reviewer and the changes being reviewed. It often results in more back-and-forth communication and can be overwhelming for both parties.

## After submitting the MR

Not every code change is trivial or a piece of cake. You can start the review process by adding comments to interesting parts of the code. Use this to point out the choices you made (e.g. constraints, implementation ideas, missing parts) or discuss things you are unsure about.

!!! info "Step by step"

    - Once you finished the ticket to-dos or need early feedback, open up an MR by pushing your changes to the Git server.
    - Make sure you follow the guidelines for a good MR.
    - Review your own MR.
    - Submit your MR.
    - Guide the review process whenever necessary.

## Getting it green

When submitting code changes, our Continuous Integration (CI) pipeline will run a suite of tools on your changes. These tools run a variety of tests, which need to pass before the code can be merged.

**Unit tests** for each service and **full-stack integration tests** are run on GitLab CI. Furthermore, we try to automate the parts of code review that can be automated, e.g. by running **linters**. These tools help enforce a consistent code style (and in some cases, best practices) and free reviewers to focus on the more valuable, higher-level parts of code review.

GitLab will notify you when any of these tools fail and displays it prominently in the merge request status widget. It also features links to the build jobs, which usually contain detailed logs that explain what's wrong. Most tools can also easily be run locally, so you should be able to reproduce the failures on your machine. (Do this before submitting the MR to save time.) This is part of the review process that most heavily depends on you, so try to fix these problems as soon as possible.
