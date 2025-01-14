# Leaner dashboard

The leaner dashboard shows various progress metrics for a specific course that the user achieved.
Each item type is styled distinctly, providing the user with quick overview of their progress.

## Surveys

A survey is marked as completed when it has been finished and either `graded` or successfully `submitted` before its deadline. If neither of these happens, the survey is displayed in a neutral grey, showing it’s still pending.

## Non-graded items

Items that are not graded, such as videos or texts, are marked as completed as soon as they have been visited.

## Quizzes and exercises

Quizzes and interactive exercises, including those from external tools, are evaluated based on performance.
These items with the `content_type` of `quiz` or `lti_exercise` are marked with three different states.

The item is marked as **completed** when:

- the percentage is greater than 95% **OR**
- the item’s maximum points are zero.

The item is marked as **warning** when:

- the percentage is greater than or equal to 50% **AND**
- the percentage is less than or equal to 95%.

The item is marked as **critical** when:

- the percentage is less than 50% **OR**
- no points are awarded for this item **AND** the item has been visited.
