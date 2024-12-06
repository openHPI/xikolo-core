# frozen_string_literal: true

class Rubric::Store < ApplicationOperation
  def initialize(rubric, params)
    super()
    @rubric = rubric
    @params = params
  end

  def call
    hints = @params.delete(:hints)
    @rubric.assign_attributes @params
    configure_processor! hints
    process_hints_and_save
    @rubric
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :peerassessment,
      purpose: 'peerassessment_rubric_hints',
      current: @rubric.hints,
      text: input
    processor.on_new do |upload|
      pid = UUID4(@rubric.peer_assessment_id).to_str(format: :base62)
      rid = UUID4(@rubric.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "assessments/#{pid}/rubrics/#{rid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: "attachment; filename=\"#{upload.sanitized_name}\"",
        content_type: upload.content_type,
      }
    end
  end

  def process_hints_and_save
    processor.parse!
    @rubric.hints = processor.result
    if processor.valid? && @rubric.save
      commit!
    else
      rollback!
    end
  end

  def commit!
    processor.commit!
    processor.obsolete_uris.each do |uri|
      Xikolo::S3.object(uri).delete
    end
    true
  end

  def rollback!
    processor.rollback!
    processor.errors.each do |_url, code, _message|
      @rubric.errors.add :hints, code.to_s
    end
    false
  end
end
