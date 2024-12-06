# Vouchers

By redeeming vouchers, users can activate paid features for a course on the Xikolo platform.
The voucher code must be created and can then be provided to the user via an external channel (e.g. an external shop or via email).
This way, we prevent dealing with payment / accounting directly in the Xikolo application.

## Products

We currently offer two different types of products to be activated by redeeming vouchers:

1. [Proctoring](proctoring.md): Users will be monitored via the webcam when taking homeworks / exams, which lets them achieve a so-called Certificate.
2. [Reactivation](reactivation.md): Self-paced courses can be reactivated, which unlocks graded assignments to achieve a Record of Achievement in courses whose regular runtime has ended.

## Creating vouchers

Vouchers can be created using the self-service UI ("Vouchers" from the platform administration dropdown) or the API endpoints provided by `shop` bridge API, so voucher codes can be created programatically by the used shop software.

## Redeeming vouchers

Vouchers for each product can be redeemed on the course details page (`/courses/the-course`).

### Proctoring

Proctoring can be booked after enrolling for a course that offers a Certificate.
The course details page as well as the proctored homeworks / exams contain links to book proctoring.

Booking proctoring is possible until the submission deadline for the first proctored homework / exam of a course has passed.
This means, exactly one homework / exam can be taken without booking proctoring (in a course with multiple proctored exercises).
In courses with only one proctored homework / exam, the exercise must be completed with proctoring to be able to receive a Certificate.

### Reactivation

Courses can not only be reactivated from the course details page but also the course list (`/courses`) or the user's personal dashboard (`/dashboard`).
For this, the user must not be enrolled in a course. The user is enrolled automatically when reactivating a course.

## Configuration

The `voucher` feature must be activated in the application configuration:

```yaml title="xikolo.yml"
voucher:
  enabled: true
```

Depending on the products that shall be available, the corresponding feature must be properly configured as well.
Please have a look at the documentation for these features.

## Integration

For integration with external shops (which can take over the money / payment handling), we provide a "Bridge API" that enables automated workflows for the following:

- creating new vouchers in order to sell them
- verifying whether, when and where vouchers have been redeemed

This bridge API is publicly documented at <https://openhpi.stoplight.io/docs/bridges/shop>.
The source files for this documentation can be found in `docs/app/bridges/shop` and should be edited using [Stoplight Studio](https://stoplight.io/studio).
