# frozen_string_literal: true

require 'addressable/uri'

class Cmi5ItemPresenter < ItemPresenter
  include UUIDHelper
  include Rails.application.routes.url_helpers

  def self.build(item, course, user, params: {})
    cmi5 = Cmi5::Item.find item['content_id']

    new cmi5:, item:, course:, user:, params:
  end

  def player_aspect_ratio
    @cmi5.player_aspect_ratio
  end

  def launch_url
    base_url = story_html_url

    params = {
      endpoint: endpoint,
      fetch: fetch,
      actor: actor,
      registration: registration,
      activityId: activity_id,
    }

    "#{base_url}?#{params.to_query}"
  end

  private

  def cmi5
    @cmi5 ||= Cmi5::Item.find(content_id)
  end

  def story_html_url
    course_content_path(content_id, cmi5.package.blob_id, 'index_lms.html')
  end

  # A URL to the LMS listener location for xAPI requests to be sent to.
  #
  # https://github.com/AICC/CMI-5_Spec_Current/blob/quartz/cmi5_spec.md#811-endpoint
  def endpoint
    routes
      .cmi5_reportings_statements_url(host: Xikolo.base_url.authority)
      .delete_suffix('/statements')
  end

  # The fetch URL is used by the AU to obtain an authorization token created and managed by the LMS.
  # The authorization token is used by the AU being launched
  #
  # https://github.com/AICC/CMI-5_Spec_Current/blob/quartz/cmi5_spec.md#82-authorization-token-fetch-url
  def fetch
    routes.cmi5_tokens_url(id: cmi5.id, host: Xikolo.base_url.authority)
  end

  # A JSON object of objectType of Agent (as defined in xAPI) that identifies the learner launching the AU
  # so the AU will be able to include it in xAPI requests.
  #
  # https://github.com/AICC/CMI-5_Spec_Current/blob/quartz/cmi5_spec.md#813-actor
  def actor
    {
      objectType: 'Agent',
      account: {
        homePage: routes.root_url(host: Xikolo.base_url.authority),
        name: @user.id.to_s,
      },
    }.to_json
  end

  def routes
    Rails.application.routes.url_helpers
  end

  # A Registration ID corresponding to the learner's enrollment for the AU being launched.
  #
  # https://github.com/AICC/CMI-5_Spec_Current/blob/quartz/cmi5_spec.md#814-registration
  def registration
    enrollment.id
  end

  def enrollment
    @enrollment ||= CourseService::Enrollment.active.find_by!(
      user_id: @user.id,
      course_id: @course.id
    )
  end

  # The Activity ID of the AU being launched.
  #
  # https://github.com/AICC/CMI-5_Spec_Current/blob/quartz/cmi5_spec.md#815-activityid
  def activity_id
    Cmi5::Item.activity_id(cmi5.id)
  end
end
