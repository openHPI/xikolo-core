# Xikolo S3

This helper gems implements some xikolo common tasks around S3 file operations. It handles the S3 client instantiations and configuration via `xikolo-config`. It provides some high-level methods to get a `Aws::S3::Bucket` or `Aws::S3::Object` to execute S3 operations.

Furthermore, it contains helper classes that process and valid given uploads to S3.

## Principles around file handling

The core philosophy is simple: **each service manages its file themselves**. The administrator assigns each service a dedicated S3 bucket (or subtrees/prefix in such). The service is responsible for:

- organize files within this space
- keeps track which files exists and to which resources they belong
- assigning and managing file meta-data (including ACls)
- delete obsolete files
- Return download/access URL to allow clients (either people or other services) to download file attachments.

This philosophy produces a few tasks that must be solved by each service (handling uploads, track file deletions etc). This gem should simplify these common tasks.

## Interacting with S3 resources

This library adds helper methods around the official AWS S3 ruby clients. Their core resources buckets (`Aws::S3::Bucket`), files/objects (`Aws::S3::Object`) are directly exposed. The official methods should be used to apply changes (set metadata, delete a file, ...).

### File references

S3 files should be referenced as **S3 uri**s like `s3://${bucket}/${key}`. They are access independent. **Database columns referencing S3 files should end with a `_uri` suffix.**

### Referencing S3 buckets

`Xikolo::S3.bucket_for(purpose)` returns a `Aws::S3::Bucket` instance based on the given purpose. The purpose should be hard-coded like `public`, `video` or `avatars`. Depending on the configuration instance specific buckets are selected.

### Access object via S3 URL

`Xikolo::S3.object(uri)` methods returns a `Aws::S3::Object` instance based on the passed URI. The URI should have the format `s3://${bucket}/${key}`.

The `Aws::S3::Object` has been extended with a `storage_uri` methods to calculate the corresponding URI for the object.

## Upload handling

Each services organizes its space independently. Therefore, a frontend cannot predict where new uploads should be stored. Instead files are uploaded into a temporary bucket. The frontend passes a reference to this upload to the services (within the normal API request). They check whether the upload fulfills their conditions and copies the file to its final place.

The uploaded files should fulfill specific conditions (like file size, file type). The condition and their state is stored as metadata on the upload itself. The frontend specifies these conditions by creating signed upload requests that must include specific metadata fields.

### Upload state (`xikolo-state`)

The state metadata field (`xikolo-state`) is designed to track the upload processing (e.g. anti-virus scanning or file type auto detection). Once all checks are passed it must be set to `accepted`. Backend services must not process files without this field or with a different value. Such upload should be rejected as invalid.

Other states are not defined yet. No processing is applied at the moment: the field is set to `accepted` during initial upload.

### Upload purpose (`xikolo-purpose`)

Different types of upload have different condition. To ensure uploads are not mixed (which might allow users to bypass checks) the `xikolo-purpose` field marks the intended upload purpose. Services must check that this field matches their expected value.

The value should start with the service identifier. It is good practice to continue with resource name and field name.

## Upload Contracts and Helpers

### Upload by id (`SingleFileUpload`)

_This is the first approach to handling uploads. It had been implemented in most services. But it has same drawbacks. Please use UploadByUri for new implementation._

The `Xikolo::S3::SingleFileUpload` processes and validates uploads that are designed to upload a single file (like a visual for a course ...).

It is instantiated with the upload id and a purpose. The upload id is used to search for accepted files within the `uploads/UUID` subtree (an upload bucket). An HTTP call to S3 is made even if the upload id is empty (as the user did not upload any file). Furthermore, it fails if there are multiple accepted files in this bucket.

The is good practice to suffix the API fields with `_upload_id` to indicate they contain a UUID referencing a upload bucket.

The object provides two methods: `empty?` returns true if the upload is not filled with any file at all and should therefore be ignored.

The `accepted_file!` methods return the `Aws::S3::Object` with the newly uploaded file. It raise a `RuntimeError` if no or multiple valid file have been found.

### Upload by URI (`UploadByUri`)

To overcome the limits of Upload by ID / `SingleFileUpload` a different contract/helper had been added. The passed value does not reference the bucket upload itself but the file itself. A URI looks like `upload://65b35eb7-25de-4dc7-95d2-86e0700f1470/origianl-file-upload.pdf`. The UUID references the upload bucket and the file name the file within the bucket.

An API can support a `_url` field to upload a new file (pass an URI), clear an existing upload (send `false`). Furthermore, such a field matches the response interface: the field returns the download URL to retrieve a previously uploaded file.

## Markup with file references

Services must often support markup fields containing references to images or documents. The `Xikolo::S3::TextWithUploadsProcessor` class helps implementing this use-case.

### Idea

The services store the markup as normal text in the database. File references are encoded as S3 URIs (`s3://bucket/key`) like other file attachments. These URIs are converted to downloadable URLs in external interfaces like HTTP responses.

After content changes the server must delete obsolete files.

Furthermore, it is supported to share file references over different markup fields (on different resources). This is implemented via a special raw representation for markup files. Instead of a text field it is a object with three fields: the `markup` (allow the user to edit it), `url_mapping` (a map of internal file URI to URL to support previews) and `other_files` (a map of URI of reusable file references to a human description like the base filename).

### Implement updates

The `Xikolo::S3::TextWithUploadsProcessor` class is instantiated with the bucket to store new files, the required purpose of new uploads, the old and new text (to be able to diff file references). An optional `valid_refs` parameter can list file URIs from other resources that can be reused. Arbitrary file URIs are rejected.

Furthermore, a `on_new` callback must be set. The callback is called with new upload objects and must return a hash with wanted metadata fields on the new file resource. It must include a `key` value to define where to store the file in the bucket.

To inspect the new content and process uploads `.parse!` must be called.

`.valid?` must be called to decide whether the proposed changes contain errors and must not be saved.

Once the changes are saved `.commit!` must be called and each URI of `.obsolete_uris` must be deleted (either synchronously or asynchronously).

If the changes are not saved, `.rollback!` must be called to delete newly created file resources that are not used.

### Generate external responses

To convert internal file URIs to usable URLs `Xikolo::S3.externalize_file_refs` must be called on each markup field. Either call it with `public: true` for public accessible files or `expires_in: SECs` to generate a temporary valid download link.

To generate a raw representation of a markup file, use `Xikolo::S3.media_refs(markup, public_or_expire_in).merge('markup' => markup)`. `media_refs`
supports `public`/`expires_in` parameters like `externalize_file_refs`.

The input markup to `media_refs` itself could be an aggregation of markup of multiple resources to support reusing these file references.

## Tests

The `Xikolo::S3.stub_responses!` allows the setup the internal S3 client in test mode that using stub requests.
It sets the `stub_responses` parameter of `Xikolo::S3::Client` to the passed in value (either `true` or a defined list of stubs).
It is a little bit difficult to find usable documentation - [the official AWS docs page](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/stubbing.html) contains some information.

Furthermore, webmock can be used to mooc requests on a more fundamental level.
