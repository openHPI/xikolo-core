# frozen_string_literal: true

class PeerAssessment::Store < ApplicationOperation
  def initialize(peerassessment, params)
    super()
    @peerassessment = peerassessment
    @params = params
  end

  def call
    instructions = @params.key?(:instructions) ? @params.delete(:instructions) : @peerassessment.instructions
    @peerassessment.assign_attributes @params
    configure_processor! instructions
    process_instructions_and_save
    @peerassessment
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :peerassessment,
      purpose: 'peerassessment_instructions',
      current: @peerassessment.instructions,
      text: input
    processor.on_new do |upload|
      pid = UUID4(@peerassessment.id).to_str(format: :base62)
      id = UUID4.new.to_str(format: :base62)
      {
        key: "assessments/#{pid}/rtfiles/#{id}/#{upload.sanitized_name}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: "attachment; filename=\"#{upload.sanitized_name}\"",
        content_type: upload.content_type,
      }
    end
  end

  def process_instructions_and_save
    processor.parse!
    @peerassessment.instructions = processor.result
    if processor.valid? && @peerassessment.save
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
      @peerassessment.errors.add :instructions, code.to_s
    end
    false
  end
end
