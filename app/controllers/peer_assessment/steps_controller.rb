# frozen_string_literal: true

class PeerAssessment::StepsController < PeerAssessment::BaseController
  inside_course
  inside_item except: %i[index update setup]
  inside_assessment except: %i[index update setup]

  skip_before_action :check_step_validity

  # TODO: remove Acfs

  before_action only: %i[update setup] do
    authorize!('peerassessment.peerassessment.edit')
  end

  layout 'peer_assessment', except: %i[index update]

  def index
    authorize!('peerassessment.peerassessment.view')

    # TODO: Remove acfs
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id]) do |assessment|
      @steps = Xikolo::PeerAssessment::Step.where peer_assessment_id: assessment.id
      @assessment_presenter = PeerAssessment::PeerAssessmentEditPresenter.new(peer_assessment: assessment)
    end

    Acfs.run

    @active_tab = :workflow

    if @steps.empty?
      @steps.push Xikolo::PeerAssessment::AssignmentSubmission.new, Xikolo::PeerAssessment::Training.new,
        Xikolo::PeerAssessment::PeerGrading.new, Xikolo::PeerAssessment::SelfAssessment.new,
        Xikolo::PeerAssessment::Results.new

      return render 'initial_setup', layout: 'edit_peer_assessment_layout'
    end

    render layout: 'edit_peer_assessment_layout'
  end

  def setup
    # TODO: Remove acfs
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id])

    Acfs.run

    # Create all steps for the assessment
    position = 0

    Xikolo::PeerAssessment::AssignmentSubmission.create!(
      position:,
      peer_assessment_id: @assessment.id
    )
    position += 1

    if params[:'Xikolo::PeerAssessment::Training']
      Xikolo::PeerAssessment::Training.create!(
        position:,
        peer_assessment_id: @assessment.id,
        optional: true
      )
      position += 1
    end

    Xikolo::PeerAssessment::PeerGrading.create!(
      position:,
      peer_assessment_id: @assessment.id
    )
    position += 1

    if params[:'Xikolo::PeerAssessment::SelfAssessment']
      Xikolo::PeerAssessment::SelfAssessment.create!(
        position:,
        peer_assessment_id: @assessment.id,
        optional: true
      )
      position += 1
    end

    Xikolo::PeerAssessment::Results.create!(
      position:,
      peer_assessment_id: @assessment.id
    )

    add_flash_message :success, I18n.t(:'peer_assessment.administration.steps.creation_success')
    redirect_to peer_assessment_steps_path
  end

  def show
    Acfs.run
    raise ActionController::RoutingError.new('Not Found') unless @current_step

    redirect_to determine_step_redirect @current_step
  end

  def update
    # TODO: Remove acfs
    @steps = Xikolo::PeerAssessment::Step.where peer_assessment_id: UUID(params[:peer_assessment_id])

    Acfs.run

    @steps.each do |step|
      step.attributes = params[:"xikolo_peer_assessment_#{step.class.name.split('::').last.underscore}"]
      step.save!
    end

    add_flash_message :success, I18n.t(:'peer_assessment.administration.steps.update_success')
    redirect_to peer_assessment_steps_path
  end

  def locked
    Acfs.run
    redirect_to peer_assessment_path short_uuid(@assessment.id) if @current_step.open?
  end

  def deadline_passed
    Acfs.run
    redirect_to peer_assessment_path short_uuid(@assessment.id) if @current_step.deadline.future?
  end

  def inaccessible
    Acfs.run
    redirect_to peer_assessment_path short_uuid(@assessment.id) if @current_step.deadline.future?
  end

  def advance
    Acfs.run unless the_participant.loaded?

    if @participant.save(params: {update_type: 'advance'})
      redirect_to peer_assessment_path short_uuid(the_assessment.id)
    else
      @participant.errors.messages[:base].each do |msg|
        add_flash_message :error, I18n.t(:"peer_assessment.advancement.errors.#{msg}")
      end
    end
  end

  def hide_course_nav?
    true
  end
end
