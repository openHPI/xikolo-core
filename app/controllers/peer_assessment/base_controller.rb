# frozen_string_literal: true

# Top level controller to encapsulate general setup stuff for the peer assessment
class PeerAssessment::BaseController < Abstract::FrontendController
  include CourseContextHelper
  include ItemContextHelper
  include PeerAssessment::PeerAssessmentContextHelper
  include PeerAssessment::AssessmentStepHelper
  include PeerAssessment::PermissionsHelper

  before_action :ensure_logged_in
  before_action :set_no_cache_headers
  before_action :set_pa_id
  before_action :load_peer_assessment

  respond_to :json

  # We already have the assessment object with the shared promise the_assessment, no need to fetch it in the presenter
  def create_item_presenter!
    Acfs.on the_item, the_section, the_course, the_assessment do |item, section, course, assessment|
      presenter_class = Module.const_get "#{item.content_type}_item_presenter".camelize
      @item_presenter = presenter_class.build item, section, course, current_user, assessment
    end
  end

  def the_participant
    promises[:participant] ||= begin
      if params[:mode] == 'teacherview'
        user_id = params[:examined_user_id]
      else
        user_id = current_user.id
      end

      promise, fulfiller = create_promise(Xikolo::PeerAssessment::Participant.new)
      Acfs.on the_assessment do |assessment|
        Xikolo::PeerAssessment::Participant.find_by(user_id:, peer_assessment_id: assessment.id) do |addition|
          fulfiller.fulfill addition
        end
      end
      promise
    end
  end

  def request_section
    promise, fulfiller = create_promise(Xikolo::Course::Section.new)
    Acfs.on the_item do |item|
      Xikolo::Course::Section.find item.section_id do |section|
        fulfiller.fulfill section
      end
    end
    promise
  end

  def request_item
    promise, fulfiller = create_promise(Xikolo::Course::Item.new)
    Acfs.on the_assessment do |assessment|
      Xikolo::Course::Item.find UUID(assessment.item_id) do |item|
        fulfiller.fulfill item
      end
    end

    promise
  end

  def the_steps
    promises[:steps] ||= begin
      promise, fulfiller = create_promise(Acfs::Collection.new(Xikolo::PeerAssessment::Step))
      Acfs.on the_assessment do |assessment|
        Xikolo::PeerAssessment::Step.where peer_assessment_id: UUID(assessment.id).to_s do |steps|
          fulfiller.fulfill steps
        end
      end

      promise
    end
  end

  def request_course
    promise, fulfiller = create_promise(Xikolo::Course::Course.new)

    if params[:course_id]
      Xikolo::Course::Course.find params[:course_id] do |course|
        fulfiller.fulfill course
      end
    else
      Acfs.on the_assessment do |assessment|
        Xikolo::Course::Course.find assessment.course_id do |course|
          fulfiller.fulfill course
        end
      end
    end

    promise
  end

  def the_assessment
    promises[:assessment] ||= Xikolo::PeerAssessment::PeerAssessment.find(
      UUID(params[:peer_assessment_id] || params[:id]).to_s
    )
  end

  protected

  # we are acting within a course, so request the permissions for this course
  def auth_context
    the_course.context_id
  end

  def enable_teacherview
    @teacherview = true if params[:mode] == 'teacherview'
    @teacher_view_params = @teacherview ? {mode: 'teacherview', examined_user_id: params[:examined_user_id]} : {}
  end
end
