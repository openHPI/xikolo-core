# Lti::Exercise regrading

There are currently no rake tasks to regrade a `Lti::Exercise`.

Use the `content_id` of the item or the actual `id` of the `Lti::Exercise` to find the associated `Lti::Gradebook`.
You can then iterate on these Gradebooks and look at the associated `Lti::Grade`, which holds the earned points in the `value` attribute.

!!! warning

    After regrading any `Lti::Exercise`, you have to call `.schedule_publication!` on the associated `Lti::Grade` to trigger the `PublishGradeJob`.
