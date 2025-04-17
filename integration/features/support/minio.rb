# frozen_string_literal: true

module Minio
  def self.delete_all
    Xikolo::S3.resource.buckets.each do |bucket|
      # First, delete all objects inside the bucket
      bucket.objects.each(&:delete)

      # Then, delete the empty bucket
      bucket.delete
    end
  end

  def self.setup
    uploads = Xikolo::S3.resource.bucket 'xikolo-uploads'
    uploads.create unless uploads.exists?
    uploads.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: uploads
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:GetObject'
            - 's3:DeleteObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{uploads.name}/*'
          Principal: {'AWS': '*'}
    POLICY

    public = Xikolo::S3.resource.bucket 'xikolo-public'
    public.create unless public.exists?
    public.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: public
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:GetObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{public.name}/*'
          Principal: {'AWS': '*'}
    POLICY

    certificates = Xikolo::S3.resource.bucket 'xikolo-certificate'
    certificates.create unless certificates.exists?

    collab = Xikolo::S3.resource.bucket 'xikolo-collabspace'
    collab.create unless collab.exists?
    collab.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: collabspace
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:GetObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{collab.name}/collabspaces/*'
          Principal: {'AWS': '*'}
    POLICY

    pinboard = Xikolo::S3.resource.bucket 'xikolo-pinboard'
    pinboard.create unless pinboard.exists?
    pinboard.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: pinboard
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:GetObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{pinboard.name}/courses/*'
          Principal: {'AWS': '*'}
    POLICY

    scientist = Xikolo::S3.resource.bucket 'xikolo-scientist'
    scientist.create unless scientist.exists?
    scientist.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: scientist
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:PutObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{scientist.name}/experiments/*'
          Principal: {'AWS': '*'}
    POLICY

    video = Xikolo::S3.resource.bucket 'xikolo-video'
    video.create unless video.exists?
    video.policy.put policy: JSON.dump(YAML.safe_load(<<~POLICY))
      Id: video
      Version: '2012-10-17'
      Statement:
        - Sid: content
          Action:
            - 's3:GetObject'
          Effect: Allow
          Resource:
            - 'arn:aws:s3:::#{video.name}/*'
          Principal: {'AWS': '*'}
    POLICY
  rescue Seahorse::Client::NetworkingError => e
    if e.message.include?('Connection refused')
      m = /Failed to open TCP connection to (.*) \(Connection refused/.match(e.message)
      raise "Cannot reach Minio/S3 at #{m[1]}. Is it running?" if m
    end

    raise e
  end
end
