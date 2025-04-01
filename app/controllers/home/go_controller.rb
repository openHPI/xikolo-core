# frozen_string_literal: true

class Home::GoController < Abstract::FrontendController
  include TracksReferrers

  skip_around_action :auth_middleware, except: :survey

  # safe redirect to external URLs from inside the application
  def redirect
    if valid_link?
      return redirect_external(params[:url]) if redirect_now

      @target_name = params[:target] || params[:url]
      @target_url = params[:url]

      # redirect to @target_url after 5 seconds
      headers['Refresh'] = "5; #{@target_url}"
    else
      head :forbidden
    end
  end

  # persistent endpoint for linking to launch controller from external sites
  # (e.g. course catalogues)
  def course
    raise Status::NotFound unless params[:course_id]

    redirect_to course_launch_path(*launch_course_params)
  end

  def pinboard
    item = course_api.rel(:item).get({id: params[:id]}).value!
    course = course_api.rel(:course).get({id: item['course_id']}).value!

    tag = Xikolo.api(:pinboard).value!.rel(:tags).get({
      type: 'ImplicitTag',
      course_id: course['id'],
      name: item['id'],
    }).value!.first

    if tag.present?
      redirect_to course_pinboard_index_path(course_id: course['course_code'], tags: tag['id'])
    else
      redirect_to course_pinboard_index_path(course_id: course['course_code'])
    end
  end

  def item
    redirect_to course_item_path(item_path_params)
  end

  def survey
    # Forward arbitrary optional query params to LimeSurvey
    # and remove tracking and other sensitive user params.
    query_params = request
      .query_parameters
      .delete_if {|key, _| key.to_s.match(/.*(tracking|referrer|user_id).*/) }
      .merge(
        r: 'survey/index', # required LimeSurvey path passed as query param
        sid: params[:id], # required LimeSurvey survey ID
        newtest: 'Y', # force a new LimeSurvey session
        xi_platform: Xikolo.config.brand # pass a platform identifier
      ).tap do |qp|
        unless current_user.anonymous?
          # add a user pseudo ID if applicable
          qp[:xi_pseudo_id] = Digest::SHA256.hexdigest(current_user.id)
        end
      end

    uri = Addressable::URI.parse(Xikolo.config.limesurvey_url)
    uri.query_values = query_params

    redirect_external(uri.to_s)
  end

  private

  def valid_link?
    Xikolo::Common::Tracking::ExternalLink.new(params[:url]).valid? params[:checksum]
  end

  def redirect_now
    params[:show_notice].blank? || cookies[:skip_redirect_notice]
  end

  def launch_course_params
    params.permit(:course_id, :auth).values
  end

  def item_path_params
    item = course_api.rel(:item).get({id: UUID4(params[:id]).to_uuid}).value!
    course = course_api.rel(:course).get({id: item['course_id']}).value!

    {course_id: course['course_code'], id: UUID4(item['id']).to_param}
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
