# Errors

Failed requests will result in an appropriate HTTP error status code and a machine-readable response body.
Any such response will adhere to the [HTTP Problem Details specification](https://tools.ietf.org/html/rfc7807) and contains all necessary details to understand the error.
This includes an error code (the `type`) for machines and a human-readable description of what the error means.

## Example

```http
HTTP 401 Unauthorized
Content-Type: application/problem+json

{
  "type": "https://dev.xikolo.de/api-docs/portalapi-beta/#error-invalid_token",
  "title": "The bearer token you provided was invalid, has expired or has been revoked.",
  "status": 401
}
```

## Handling errors

When expecting certain errors to occur, always check for their `type` and not the HTTP status code.
We strive to provide semantically correct status codes for each error situation - these provide information, e.g. whether a request can be retried or a response can be cached, to intermediaries or your request middleware stack.
While there may be overlap between the status code and an error `type`, there is likely not a 1-to-1 mapping between them.
For example, there may be multiple reasons why a response has a status code of `400 Bad Request`.

## Known errors

### `unauthenticated`

You will receive this error when you forgot to authenticate the request using the `Authorization` HTTP request header.

See [Authentication](./authentication.md).

### `invalid_token`

This means the token in the `Authorization` HTTP request header is not a valid token or has expired.

See [Authentication](./authentication.md).

### `accept_header_missing`

To ensure that API version usage can be monitored, and to provide clients with a way to be aware of upcoming breaking changes, we require the presence of an `Accept` request header.
This error occurs when requesting an API resource without providing the desired response media type.

See [Content Negotiation](./negotiation.md).

### `unsupported_content_type`

None of the media types provided in the request's `Accept` are available for this resource.
This likely means that you are requesting an old version of an endpoint, which is no longer available.

See [Content Negotiation](./negotiation.md).

### `internal_server_error`

This error can occur when a request to the `POST enrollments` endpoint cannot be processed internally.

### `course_or_user_not_found`

For the `GET enrollments` endpoint, this error can occur when a request is sent with a `course_id` or `user_id` that does not exist.
For the `POST enrollments` endpoint, this error can occur when the `user_id` or `course_id`, or both, do not exist.

### `invalid_request`

This error is raised whenever there are syntax errors in the request, e.g. missing commas between parameters.
