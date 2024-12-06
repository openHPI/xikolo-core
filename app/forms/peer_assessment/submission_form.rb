# frozen_string_literal: true

class PeerAssessment::SubmissionForm
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor \
    :additional_attempts,
    :attachments,
    :disallowed_sample,
    :gallery_opt_out,
    :grade,
    :id,
    :peer_assessment_id,
    :reset,
    :shared_submission_id,
    :submitted,
    :team_name,
    :text,
    :user_id

  def initialize(submission)
    submission.each do |key, value|
      send(:"#{key}=", value) if respond_to?(key.to_sym)
    end
  end

  def persisted?
    id
  end

  def save(params: {})
    return false unless valid?

    if persisted?
      Xikolo.api(:peerassessment).value!.rel(:submission).patch(as_json, params.merge!(id:)).value!
    else
      submission = Xikolo.api(:peerassessment).value!.rel(:submission).post(as_json, params).value!
      self.id = submission['id']
    end

    true
  end

  def delete
    if persited?
      Xikolo.api(:peerassessment).value!.rel(:submission).delete(id:).value!
    end
  end

  def attributes=(hash)
    hash.each do |key, value|
      send(:"#{key}=", value)
    end
  end

  def attributes
    {
      'peer_assessment_id' => nil,
      'text' => nil,
      'reset' => false,
      'user_id' => nil,
      'additional_attempts' => 0,
      'submitted' => false,
      'disallowed_sample' => nil,
      'gallery_opt_out' => false,
      'attachments' => [],
      'grade' => 0,
      'shared_submission_id' => nil,
      'team_name' => nil,
    }
  end
end
