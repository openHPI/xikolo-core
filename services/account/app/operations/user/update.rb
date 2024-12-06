# frozen_string_literal: true

class User::Update < ApplicationOperation
  include Facets::Tracing

  def initialize(user, params)
    super()

    @user = user
    @params = params
    @replaced_uri = nil
    @upload_error = nil
  end

  def call
    User.transaction do
      # PUT also sends `password_digest` that will override even new
      # `password`s. Therefore we're dropping `password_digest` when
      # `password` is given.
      @params.delete(:password_digest) if @params[:password].present?
      # Also, ensure that the `email` is not written as it is read-only.
      # See API::UsersController#update as well.
      @params.delete(:email)

      # Remove the existing avatar if no `avatar_uri` nor `avatar_upload_id`
      # is passed in as parameter. This sets the `avatar_uri` to `nil` for the
      # user and removes the S3 object for "internal" avatars
      # (see #remove_replaced_avatar! below).
      # Update the avatar if a S3 upload or external avatar URI is provided.
      if remove_avatar?
        @replaced_uri = @user.avatar_uri unless @user.external_avatar?
        @user.update @params.except(:avatar_upload_id)
      elsif external_avatar_url?
        # Non-S3 upload, thus simply set the external avatar URL.
        @user.update @params.except(:avatar_upload_id)
      else
        # S3 file upload.
        # Only upload via upload_id if no URI is provided.
        # Upload via ID is deprecated.
        if @params[:avatar_uri].present?
          upload_via_uri
        elsif @params[:avatar_upload_id].present?
          upload_via_id
        end
        # Do not update the avatar_uri with the passed in value but the S3
        # storage URL (already set in `upload_via_uri` and `upload_via_id`).
        @user.update @params.except(:avatar_uri, :avatar_upload_id)
      end
    end

    # This is done here to not make the transaction fail only because a file
    # deletion job cannot be enqueued.
    process_errors! if @upload_error
    remove_replaced_avatar!

    @user
  end

  private

  def remove_avatar?
    @params.key?(:avatar_uri) && @params[:avatar_uri].nil? &&
      !@params.key?(:avatar_upload_id)
  end

  def external_avatar_url?
    # It is an external (non-S3) URI if no S3 upload URI
    # nor an S3 upload ID is provided.
    @params[:avatar_uri].present? &&
      !@params[:avatar_uri].starts_with?('upload://') &&
      !@params.key?(:avatar_upload_id)
  end

  def upload_via_id
    # Validate upload
    upload = Xikolo::S3::SingleFileUpload.new @params[:avatar_upload_id],
      purpose: 'account_user_avatar'
    return if upload.empty?

    upload_object = upload.accepted_file!
    original_filename = File.basename upload_object.key
    extname = File.extname original_filename
    bucket = Xikolo::S3.bucket_for(:avatars)
    uid = UUID4(@user.id).to_str(format: :base62)
    revision = revision(@user.avatar_uri)
    object = bucket.object("avatars/#{uid}/avatar_v#{revision}#{extname}")

    # Save upload to xi-avatars bucket
    object.copy_from(
      upload_object,
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload_object.content_type,
      content_disposition: "inline; filename=\"#{original_filename}\""
    )
    @replaced_uri = @user.avatar_uri
    @user.avatar_uri = object.storage_uri
  rescue Aws::S3::Errors::ServiceError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    @upload_error = 'could not process file upload'
  rescue RuntimeError
    @upload_error = 'invalid upload'
  end

  def upload_via_uri
    # Validate upload
    upload = Xikolo::S3::UploadByUri.new \
      uri: @params[:avatar_uri],
      purpose: 'account_user_avatar'
    unless upload.valid?
      @upload_error = 'Upload not valid - ' \
                      'either file upload was rejected or access to it is forbidden.'
      return
    end

    # Save upload to xi-avatars bucket
    uid = UUID4(@user.id).to_str(format: :base62)
    revision = revision(@user.avatar_uri)
    result = upload.save \
      bucket: :avatars,
      key: "avatars/#{uid}/avatar_v#{revision}#{upload.extname}",
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload.content_type,
      content_disposition: "inline; filename=\"#{upload.sanitized_name}\""
    if result.is_a?(Symbol)
      @upload_error = 'Could not save file - ' \
                      'access to destination is forbidden.'
      return
    end
    @replaced_uri = @user.avatar_uri
    @user.avatar_uri = result.storage_uri
  end

  def revision(avatar_uri)
    /.*_[rv](?<revision>[0-9]+)(?:\.[a-z]{2,4})?/ =~ avatar_uri
    revision ||= 0
    revision.to_i + 1
  end

  def process_errors!
    if @params[:avatar_uri].present?
      @user.errors.add :avatar_uri, @upload_error
    else
      @user.errors.add :avatar_upload_id, @upload_error
    end
  end

  def remove_replaced_avatar!
    return unless @replaced_uri

    FileDeletionJob.set(wait: 1.hour).perform_later(@replaced_uri)
  end
end
