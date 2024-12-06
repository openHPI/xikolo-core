# frozen_string_literal: true

class PeerAssessment::ReviewForm
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :id, :text, :optionIDs, # rubocop:disable Naming/MethodName
    :award, :feedback_grade, :extended,
    :deadline, :step_id, :submitted

  def initialize(review)
    self.id = review['id']
    self.text = review['text']
    self.optionIDs = review['optionIDs']
    self.award = review['award']
    self.feedback_grade = review['feedback_grade']
    self.step_id = review['step_id']
    self.extended = review['extended']
    self.deadline = review['deadline']
  end

  def persisted?
    id
  end

  def save
    return false unless valid?

    if persisted?
      Xikolo.api(:peerassessment).value!.rel(:review).patch(as_json, id:).value!
    else
      review = Xikolo.api(:peerassessment).value!.rel(:review).post(as_json).value!
      self.id = review['id']
    end

    true
  end

  def delete
    if persisted?
      Xikolo.api(:peerassessment).value!.rel(:review).delete(id:).value!
    end
  end

  def attributes
    {
      'text' => nil,
      'optionIDs' => nil,
      'award' => nil,
      'feedback_grade' => nil,
      'submitted' => false,
      'extended' => false,
      'deadline' => nil,
    }
  end
end
