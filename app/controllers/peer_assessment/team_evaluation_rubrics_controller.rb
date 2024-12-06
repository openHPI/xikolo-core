# frozen_string_literal: true

class PeerAssessment::TeamEvaluationRubricsController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper

  inside_course

  before_action :load_assessment

  before_action :set_tabs
  before_action :load_rubric, only: %i[moveup movedown destroy]

  layout 'edit_peer_assessment_layout'

  def index
    authorize! 'peerassessment.peerassessment.view'
    Acfs.on the_assessment do |assessment|
      @rubrics = Xikolo::PeerAssessment::Rubric.where(
        peer_assessment_id: assessment.id,
        team_evaluation: true
      ) do |rubrics|
        @rubric_presenters = build_rubric_presenters rubrics
      end
    end

    Acfs.run
  end

  def new
    authorize! 'peerassessment.peerassessment.edit'
    @rubric = Xikolo::PeerAssessment::Rubric.new
    Acfs.run
  end

  def create
    authorize! 'peerassessment.peerassessment.edit'
    Xikolo::PeerAssessment::Rubric.create!(
      create_params.merge(
        peer_assessment_id: params[:peer_assessment_id],
        team_evaluation: true
      )
    )

    add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.create_success')
    redirect_to peer_assessment_team_evaluation_rubrics_path short_uuid(@assessment.id)
  end

  def moveup
    authorize! 'peerassessment.peerassessment.edit'
    if @rubric.update_attributes params, params: {moveup: true}
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_failure')
    end

    redirect_to peer_assessment_team_evaluation_rubrics_path
  end

  def movedown
    authorize! 'peerassessment.peerassessment.edit'
    if @rubric.save params: {movedown: true}
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_failure')
    end

    redirect_to peer_assessment_team_evaluation_rubrics_path
  end

  def destroy
    authorize! 'peerassessment.peerassessment.edit'
    if @rubric.delete
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.destroy_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.destroy_failure')
    end

    redirect_to peer_assessment_team_evaluation_rubrics_path
  end

  private

  def set_tabs
    @active_tab = :team_evaluation_rubrics
  end

  def create_params
    params.require(:xikolo_peer_assessment_rubric).permit :title, :hints
  end

  def load_rubric
    @rubric = Xikolo::PeerAssessment::Rubric.find UUID(params[:id])
    Acfs.run
  end
end
