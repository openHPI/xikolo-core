# Course list banner

Promotional banners can be added to the course list, e.g. to advertise related offers.

For convenience, a rake task can be used to configure a banner for certain period.

!!! tip

    Use the following command to list all avaiable `rake` tasks:
    ```bash
    xikolo-web rake -T
    ```

## Create a new banner

To create a new banner for the course list, follow the instructions below.

1. Make sure all required information is available, most importantly, the banner image is available via a public link (e.g., attached to the YouTrack ticket).

    !!! info

        Right-click on the banner preview and select "Copy link address" or open the banner and select "Copy image address" to copy the image URL for the banner.
        The image URL from YouTrack looks like this: `https://dev.xikolo.de/youtrack/api/files/12-3456?sign=s0m3HashValu3&updated=1234567891011`.

        Any other publicly available image URL can be used as well since the banner is downloaded from the provided URL and uploaded to the S3 bucket.

2. Collect optional configuration parameters, such as the publication date, expiry date, and the link URL.

    !!! tip

        The banner link URL supports both absolute and relative paths.

3. SSH to the platform's `web-*` VM.
4. Run the `banner:create` rake task. The task will guide you through the process.

    ```bash
    xikolo-web rake banner:create
    ```

    ```bash title="Sample rake task execution"
    Please enter the banner URL ("https://dev.xikolo.de/youtrack/api/files/the-banner"):
    https://dev.xikolo.de/youtrack/api/files/73-6689?sign=MTYzNjkzNDQwMDAwMHwyNS0zMjZ8NzMtNjY4OXxoV2xYbVlsZC13d1Q3OUlsRDFocGFvdjZGNEJw%0D%0AbmxVM3ROOFVZNzhFVDA4DQo%0D%0A&updated=1633335363829
    Please enter the banner filename ("banner.png"):
    my_banner.png
    Please enter the UTC publishing date ("24-12-2021 09:15") or skip ([Enter], default: now):

    Please enter the UTC expiry date ("24-12-2021 09:15") or skip ([Enter], default: none):
    31-12-2042 20:42
    Please enter the banner alt text ("Now 20 million enrollments!"):
    Important information to share.
    Please enter the banner link URL ("https://www.example.com") or skip ([Enter]):
    /pages/about
    Please enter the banner link target ("self", "blank") or skip ([Enter], default: "self"):
    blank
    Starting the banner upload to S3...
    Saved the banner to S3.
    Creating the banner record...
    Created the banner record. Please verify.
    ```

5. Check the output of the rake task for errors, e.g. AWS / S3 errors for the banner upload or Rails-related errors for the `Banner` record creation.

## Server-side caching

The current course list banner is cached on the server-side for 30 minutes.
So don't panic if the banner does not show up immediately (assuming the rake task has finished without errors).

You can speed up showing / removing a banner by deleting the corresponding Rails cache key.

1. SSH to the platform's `task` or `web-*` VM.
2. Start the Rails console.

    ```bash
    xikolo-web rails c
    ```

3. Delete the caching key for the course list banner.

    ```ruby
    Rails.cache.delete('web/courses/banners/current')
    ```

    !!! tip

        You can list all caching keys with `Rails.cache.redis.keys`.

## Delete a banner

When deleting a `Banner` record, the corresponding S3 file will be removed as well.
Due to caching, the current banner information will be available for at least 30 more minutes.
The referenced S3 file will be deleted asynchronously, so this usually should not cause issues.
However, deleting a currently displayed banner is not recommended as it may lead to a corrupted banner image on the course list page.

!!! danger

    Make sure to only delete expired banners or clean up the Rails cache for the current banner.
