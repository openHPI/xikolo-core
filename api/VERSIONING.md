# API Versioning

Due to changing customer requests or new features, the API may have to change from time to time.
Because mobile apps can not be rolled out as easily as Xikolo's web version, managing these changes safely is very important.
(More importantly, we cannot force users to install new versions of our mobile apps immediately.)

Thus, special care needs to be taken so that:

- changes to the API are backwards-compatible, or
- if there is no way to keep changes backwards-compatible, the old and new versions of the API should be run side-by-side for a while.

To benefit from this approach, API clients should always send along the version they were built against when requesting data from or sending data to the API.
This allows the API to respond with the correct version of the requested endpoint, and - if applicable - notify the client of the upcoming expiry of this version.

## Version Negotiation

When requesting data from an API endpoint, e.g. `/api/v2/courses`, the API will by default respond with the newest version of that endpoint:

```http
GET /api/v2/courses HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json; xikolo-version=3.8
```

As explained above, clients should always send the number of the last major API version they support.
They can use the `Accept` header to specify the corresponding content type:

```http
GET /api/v2/courses HTTP/1.1
Accept: application/vnd.api+json; xikolo-version=2

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json; xikolo-version=2.1
```

Deprecated versions can be recognized based on the presence of the `Sunset` header:

```http
GET /api/v2/courses HTTP/1.1
Accept: application/vnd.api+json; xikolo-version=1

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json; xikolo-version=1.12
Sunset: Tue, 15 Aug 2017 00:00:00 GMT
```

This date signals the last day of support for the given API version.
It will be communicated to the client developers well in advance, so that new client versions can be released in time.
The date should then be used by clients to recommend upgrading to the latest version e.g. 2 weeks, 1 week and 3 days before expiration.

## Client Implementation Guide

### For distributed code (e.g. mobile apps)

1. When communicating with the API, send an appropriate `Accept` header that contains the API version the client was built against.
2. _(optional)_ Send a request to the API when starting the app.
3. Check API responses for the presence of the `Sunset` header.
4. If the header is present and the date is within a certain range of the current date, notify users they should update, or the app may stop working on the given date.
5. At this point, a new release of the app should be available.
   This release should support the new version of the API (and thus send the appropriate `xikolo-version` parameter as part of the `Accept` header).

### For server-side code

1. When communicating with the API, send an appropriate `Accept` header that contains the API version the client was built against.
2. Check API responses for the presence of the `Sunset` header.
3. If the header is present, log the value and notify a developer.
4. The developer should verify how API changes in the latest non-deprecated version affect the client code.
   If applicable, breaking API changes should be taken care of.
5. Finally, use the latest version of the API by updating the `xikolo-version` parameter that is part of the `Accept` header.
