# Authentication

Currently, all endpoints are protected from anonymous access.
To access them, you need a valid OAuth 2.0 Bearer Token.
As endpoints for token exchange do not yet exist, please request a shared secret from your contact at openHPI.

## Authenticating a request

To authenticate, add an `Authorization` header to your HTTP request:

```http
Authorization: Bearer 7901617074e0289b034969135fbfad729c2377912b2d23b01415feb9b3ec2e0e
```
