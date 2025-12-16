# frozen_string_literal: true

module CourseService
class Richtext::Store < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :richtext

  def initialize(richtext, params)
    super()
    @richtext = richtext
    @params = params
  end

  def call
    text = @params.delete(:text)
    richtext.assign_attributes @params
    configure_processor! text
    process_text_and_save
    richtext
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new(bucket: :course,
      purpose: 'course_richtext',
      current: richtext.text,
      text: input,
      valid_refs:)
    processor.on_new do |upload|
      cid = UUID4(richtext.course_id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "courses/#{cid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
  end

  def process_text_and_save
    processor.parse!
    richtext.text = processor.result
    if processor.valid? && richtext.save
      commit!
    else
      rollback!
    end
  end

  def commit!
    processor.commit!
    processor.obsolete_uris.each do |uri|
      RichtextFileDeletionWorker.perform_in 1.hour, uri
    end
    true
  end

  def rollback!
    processor.rollback!
    processor.errors.each do |_url, code, _message|
      richtext.errors.add :text, code.to_s
    end
    false
  end

  def valid_refs
    other_markup = Richtext
      .where(course_id: richtext.course_id)
      .where.not(id: richtext.id)
      .pluck(:text).join("\n")
    other_markup += "\n#{richtext.course.description}"
    Xikolo::S3.extract_file_refs(other_markup)
  end
end
end
