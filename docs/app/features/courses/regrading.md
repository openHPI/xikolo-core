# Quiz regrading

For quizzes, five different types of regrading are possible:

- Jackpot
- Remove answer
- Update question
- Update all questions
- Select answer for all

Every regrading type can be performed with via `rake` task on the production systems.

!!! tip

    Use the following command to list all avaiable `rake` tasks:
    ```bash
    xikolo-quiz rake -T
    ```

!!! warning

    After executing one of the regrading tasks below, copy-paste the command to update the course results from the output.
    It looks like this:

    ```bash
    xikolo-quiz rake regrading:just_update_course QUIZ_ID={quiz_id}
    ```

    For example, this allows to perform multiple regradings for a quiz firt, e.g. jackpot regrading for multiple questions, before updating the results for the quiz only once. Use the quiz' content ID.

## Jackpot

Give all users that have submitted this quiz the maximum amount of points for the question.

```bash
xikolo-quiz rake regrading:jackpot QUESTION_ID={question_id}
```

## Remove answer

Remove an answer from a question in a quiz, remove the corresponding `submission_answers`, and set a new timestamp for `quiz_version_at` in the submissions.

```bash
xikolo-quiz rake regrading:remove_answer ANSWER_ID={answer_id}
```

## Update question

Update points for a question after additional answer options have been added via the user interface (for freetext questions) or answer options have been removed or changed (for other questions).
This resets points to `nil` and sets a new timestamp for `quiz_version_at`.

```bash
xikolo-quiz rake regrading:update_question QUESTION_ID={question_id}
```

## Update all questions

Update points for an entire quiz after changing the points distribution via the user interface, e.g. after deleting a question.

```bash
xikolo-quiz rake regrading:update_all_questions QUIZ_ID={quiz_id}
```

## Select answer for all

Select a specific answer for all submitted questions and recalculate the points.

```bash
xikolo-quiz rake regrading:select_answer_for_all ANSWER_ID={answer_id}
```
