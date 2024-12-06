# frozen_string_literal: true

require 'xikolo/s3'

class Video::Store < ApplicationOperation
  def initialize(video, params)
    super()

    @video = video
    @params = params
    @new_uris = []
    @replaced_uris = []
    @errors = []
  end

  def call
    # Saving the params to the video record in memory ensures, in the case of any error,
    # that the new values are cached for the form fields.
    # The *_upload_id and *_url params are excluded, as they don't exist on the model.
    # The description currently written to the database is needed by the processor,
    # so we set it later (see handle_description!).

    @video.assign_attributes @params.except(:reading_material_upload_id, :slides_upload_id, :transcript_upload_id,
      :subtitles_upload_id, :reading_material_url, :transcript_url, :slides_url, :description,
      :reading_material_uri, :slides_uri, :transcript_uri)
    handle_description!
    handle_attachments!
    ::Video::Video.transaction do
      if @params.key? :subtitles_upload_id
        @video.save! # Necessary for attaching subtitles if the video is in process of creation
        process_subtitles! @params.delete(:subtitles_upload_id)
      end
      @video.save! if @errors.empty?
    end
    if @errors.empty?
      delete_replaced_files!
      processor&.commit!
    else
      process_errors!
    end

    @video
  rescue ActiveRecord::RecordInvalid
    process_errors!
    @video
  end

  private

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :video,
      purpose: 'video_description',
      current: @video.description,
      text: input
    processor.on_new do |upload|
      vid = UUID4(@video.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "videos/#{vid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
  end

  def handle_description!
    return unless @params.key? :description

    description = @params.delete(:description)
    if description.blank?
      @video.description = description
      return
    end
    configure_processor! description

    # Setting the record's description to the unprocessed description (in memory!)
    # ensures, in the case of any error during the processing of the description,
    # that the faulty description is still cached for the form field.
    # If the new description is empty, we can just bypass the processing.
    # We set the description after the processor is configured,
    # as the processor needs the description currently written to the database.
    @video.description = description
    processor.parse!
    @video.description = processor.result
    return @replaced_uris += processor.obsolete_uris if processor.valid?

    processor.errors.each do |_url, code, _message|
      @errors << [:description, code.to_sym]
    end
    raise ActiveRecord::RecordInvalid
  end

  def process_subtitles!(subtitles_upload_id)
    upload = Xikolo::S3::SingleFileUpload.new(subtitles_upload_id, purpose: 'video_subtitles')
    return if upload.empty?

    upload_object = upload.accepted_file!
    case upload_object.extname
      when '.zip'
        Video::Subtitle.extract! upload_object, @video
      when '.vtt'
        lang = Video::Subtitle.extract_lang upload_object.sanitized_name
        if lang
          content = upload_object.get.body.read
          Video::Subtitle.attach! content, lang, @video, automatic: false
        else
          @errors << %i[subtitles language_missing]
        end
    end
  rescue Video::InvalidSubtitleError => e
    # TODO: ActiveModel contract violation
    #
    # This code assigns an error to "attributes" (e.g. `invalid_subtitles`)
    # that DO NOT exist on a Video. This does not work in Rails 6.1 anymore,
    # as the ActiveModel errors collection and error classes will try to look
    # up the attribute definitions and values for localization.
    # Any respond or rendering of errors with an error added to
    # `:invalid_subtitle` ends up raising this exception:
    #
    #     #<NoMethodError: undefined method `invalid_subtitle' for #<Video>>
    #
    # As a workaround and to not change the API contract by changing
    # fields, an unused dump attribute called :invalid_subtitle exists
    # to the Video model. TODO: Remove unused attribute :invalid_subtitle from the Video model
    @video.subtitles.first.delete # We don't want to pass the current invalid subtitles to the next call of new
    @errors << [:subtitles, I18n.t(
      'items.video.errors.invalid_subtitle',
      count: e.identifiers.length,
      identifiers: e.identifiers.join(', ')
    )]

    raise ActiveRecord::RecordInvalid
  end

  # New uploads are passed via upload_ids
  # Deletion requests are passed via urls
  def handle_attachments!
    %i[reading_material slides transcript].each do |type|
      # Handle deletion requests (..._url = nil)
      if @params.key? :"#{type}_url"
        value = @params.delete :"#{type}_url"
        if value.nil?
          @replaced_uris << @video[:"#{type}_uri"]
          @video.assign_attributes "#{type}_uri": nil
        end
      end

      # Handle upload requests
      purpose = type == :reading_material ? 'video_material' : "video_#{type}"
      process_upload!(type, purpose)

      next
    end
  end

  def process_upload!(type, purpose)
    ref = @params.delete(:"#{type}_uri").presence || @params.delete(:"#{type}_upload_id")

    return if ref.nil?

    object =  if ref.starts_with?('upload://')
                upload_via_uri(ref, purpose)
              else
                upload_via_id(ref, purpose)
              end

    return if object.blank?

    @replaced_uris << @video["#{type}_uri"]
    @video.assign_attributes("#{type}_uri": object.storage_uri)
    @new_uris << object.storage_uri
  rescue Aws::S3::Errors::ServiceError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    @errors << %I[#{type}_uri upload_error]
    raise ActiveRecord::RecordInvalid
  rescue RuntimeError
    @errors << %I[#{type}_uri upload_error]
    raise ActiveRecord::RecordInvalid
  end

  def delete_replaced_files!
    return if @replaced_uris.empty?

    # Handle upload and deletion request for the same uri
    @replaced_uris.to_set

    # Don't delete the file if it is still referenced by any other video
    @replaced_uris.each do |uri|
      next if Video::Video.referenced? uri

      S3FileDeletionJob.set(wait: 1.hour).perform_later uri
    end
    @replaced_uris = []
  end

  def process_errors!
    delete_already_uploaded_files!
    processor&.rollback!
    @errors.each do |field, error|
      # In some cases, `error` is not a String but a Hash with additional details.
      # We must force the code here to pass `error` as the second position argument.
      @video.errors.add(field, error, **{})
    end
  end

  def delete_already_uploaded_files!
    # To ensure atomicity (in case of a failing update action)
    @new_uris.each {|uri| Xikolo::S3.object(uri).delete }
    @new_uris = []
  end

  def upload_via_id(upload_ref, purpose)
    upload = Xikolo::S3::SingleFileUpload.new(upload_ref, purpose:)

    return if upload.empty?

    upload_object = upload.accepted_file!

    bucket = Xikolo::S3.bucket_for(:video)
    uid = UUID4(@video.id).to_str(format: :base62)
    key = "videos/#{uid}/#{upload_object.unique_sanitized_name}"
    object = bucket.object(key)

    # Save upload to xi-video's bucket (xikolo-public)
    object.copy_from(
      upload_object,
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      content_type: 'application/pdf',
      cache_control: 'public, max-age=7776000',
      content_disposition: "attachment; filename=\"#{upload_object.sanitized_name}\""
    )
    object
  end

  def upload_via_uri(uri, purpose)
    # Validate upload
    upload = Xikolo::S3::UploadByUri.new(uri:, purpose:)

    unless upload.valid?
      @errors << [
        :uri,
        'Upload not valid - either file upload was rejected or access to it is forbidden.',
      ]
      return
    end

    # Save upload to xi-video bucket
    uid = UUID4(@video.id).to_str(format: :base62)

    result = upload.save \
      bucket: :video,
      key: "videos/#{uid}/#{upload.upload.unique_sanitized_name}",
      content_disposition: "attachment; filename=\"#{upload.sanitized_name}\"",
      content_type: upload.content_type,
      acl: 'private'

    if result.is_a?(Symbol)
      @errors << %I[uri_error upload_error]

      return
    end

    result
  end
end
