# Proctoring

!!! danger

    The proctoring feature is deprecated and will be removed.

Proctoring is implemented with the solution provided by [SMOWL](https://smowl.net/).

!!! note

    Allowing users to book proctoring requires [vouchers](vouchers.md) to be enabled.

## Platform configuration

Proctoring requires different options to be provided, which are listed below.

First of all, a store URL (or multiple URLS for different languages) must be set for integration with the external shop.

```yaml title="xikolo.yml"
proctoring:
  store_url: "https://shop.example.org/voucher/qualified-certificate"
```

```yaml title="xikolo.yml"
proctoring:
  store_url:
    de: "https://shop.example.org/gutscheine/qualifiziertes-zertifikat"
    en: "https://shop.example.org/voucher/qualified-certificate"
```

For configuring the proctoring solution provided by SMOWL, the following options are relevant:

!!! example

    ```yaml title="xikolo.yml"
    proctoring_smowl_options:
      # Thresholds for proctoring passed/failed features.
      # If the user has the same number of images or more than the threshold,
      # the activity will be treated as failed.
      nobodyinthepicture: 5
      # Wrong user detected.
      wronguser: 0
      # More than one user detected.
      severalpeople: 1
      # The user has covered the camera.
      webcamcovered: 0
      # Bad lighting or incorrect position.
      invalidconditions: 5
      # The webcam was rejected.
      webcamdiscarted: 5
      # Cheating attempt detected (e.g. the user tried showing a photograph
      # to the camera).
      notallowedelement: 0
      # The user had another tab open during the quiz. When another tab has the
      # focus, the camera does not send images, which is not allowed.
      othertab: 5
      # SMOWL received black images (usually a technical issue, e.g. the webcam is
      # not working properly or the laptop is closed). We allow five black images
      # as this can happen due to technical reasons.
      emptyimage: 5
      # A not supported browser is used.
      notsupportedbrowser: 5
      # The user does not have a webcam (connected).
      nocam: 5
      # Another application is blocking the webcam.
      otherapp: 5
      # Minimum number of correct images.
      # If the user has more correct images than the threshold, the activity
      # will be treated as passed. Set it to '0' to deactivate this option.
      correctimages: 1
    ```

The credentials for SMOWL's REST API are set via the secrets:

```yaml title="secrets.yml"
  smowl_entity: my_entity
  smowl_license_key: my_license_key
  smowl_password: my_password
```

Last, the `proctoring` feature flipper must be enabled for the platform (usually for all courses and all logged-in users).

## Course configuration

With the enabled feature flipper, a course can be set to be proctored in the "Certificates" section in the "Course Properties" in the course administration.

When the course is set to proctored, the homeworks / exams must be activated for proctoring as well.
For this, navigate to "Structure & Content", edit the respective item, and toggle the "Proctored" option.

!!! note

    Proctoring must be initially activated for a platform (and individual courses) on SMOWL-side as well.
