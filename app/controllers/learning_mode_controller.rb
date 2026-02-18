# frozen_string_literal: true

class LearningModeController < Abstract::FrontendController
  include CourseContextHelper

  before_action :ensure_logged_in
  require_feature 'quiz_recap', only: :index
  respond_to :json

  inside_course only: :index

  def index
    # Wait for the navigation and header to load
    Acfs.run

    render
  end

  def review
    if params[:quiz_id] && params[:course_id]
      Xikolo::Course::Item.find_by content_id: params[:quiz_id] do |item_tmp|
        @item = Xikolo::Course::Item.find item_tmp.id
      end
      Acfs.run
      redirect_to course_item_path(course_id: params[:course_id], id: @item.prev_item_id || @item.id),
        status: :see_other
    else
      add_flash_message :error, t(:'flash.error.params_missing_learn_review')
      redirect_to learn_path, status: :see_other
    end
  end

  private

  def auth_context
    if params[:course_id]
      the_course.context_id
    else
      :root
    end
  end
end
