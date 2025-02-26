# Classifiers

To ease organization and discoverability of courses, they can be annotated using **classifiers**.
Classifiers themselves are grouped into **clusters**, so that courses can be tagged along multiple dimensions, such as "level of difficulty" or "topic".

Platform admins can define the clusters available on a platform, as well as create, edit or delete classifiers for a cluster.
Course admins can then select (or create) the matching classifiers for their course.

Clusters can either be visible or hidden.
This determines whether they will be shown to end-users, e.g. as filter dropdowns on the course list.
Even hidden clusters can be used for filtering on the course list, however not via the user interface (only via query parameter in the URL).

Classifiers are also used as **tags** on the course details page and on course cards.
For course cards, clusters must be configured (as array) to be considered.

!!! example

    ``` yaml
    course_card:
      classifier_clusters:
        - topic
    ```
For the course details page, tags are only shown if enabled via config.

!!! example

    ``` yaml
    course_details:
      list_classifiers: true # default
    ```

Classifiers from invisible clusters are not included, even if explicitly configured for the course cards.
