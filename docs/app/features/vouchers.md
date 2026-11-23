# Vouchers

By redeeming vouchers, users can activate paid features for a course on the Xikolo platform.
The voucher code must be created and can then be provided to the user via an external channel (e.g. an external shop or via email).
This way, we prevent dealing with payment / accounting directly in the Xikolo application.

## Products

We currently offer the following product to be activated by redeeming vouchers:

1. [Reactivation](reactivation.md): Self-paced courses can be reactivated, which unlocks graded assignments to achieve a Certificate in courses whose regular runtime has ended.

## Creating vouchers

Choose **Vouchers** from the platform administration dropdown to create voucher codes.

## Redeeming vouchers

Vouchers for each product can be redeemed on the course details page (`/courses/the-course`).

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
