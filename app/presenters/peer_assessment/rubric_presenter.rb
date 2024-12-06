# frozen_string_literal: true

class PeerAssessment::RubricPresenter < Presenter
  def_delegators :rubric, :id, :title, :hints, :options
  attr_accessor  :rubric

  def self.create(rubric)
    new rubric:
  end

  def to_param
    UUID(id).to_param
  end

  def options
    @options ||= Xikolo.api(:peerassessment).value!.rel(:rubric_options).get(rubric_id: id).value!
  end
end
