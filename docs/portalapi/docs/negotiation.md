# Content Negotiation

- `Accept` header is required
- Versioning per endpoint via media type parameter, e.g. `application/vnd.openhpi.course+json;v=1.1`
- Semantic Versioning (response will contain the latest compatible minor release), e.g. requesting `v=1.0` will result in a `v=1.1` response, but `v=2.3` will have to be requested explicitly with `v=2.x`

## Future Work

- Deprecated, but still supported endpoints will contain a `Sunset` response header
