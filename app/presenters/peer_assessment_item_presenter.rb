# frozen_string_literal: true

class PeerAssessmentItemPresenter < ItemPresenter
  include Rails.application.routes.url_helpers

  def_delegator :@item, :section_id

  def self.build(item, section, course, user, assessment = nil, **) # rubocop:disable Metrics/ParameterLists
    presenter = new(item:, course:, section:, user:, assessment:)
    presenter.redirect!
    presenter
  end

  def default_icon
    'money-check-pen'
  end

  def redirect!
    @redirect = peer_assessment_path UUID(@item.content_id).to_param
  end
end
