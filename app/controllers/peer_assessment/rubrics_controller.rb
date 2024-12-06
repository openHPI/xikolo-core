# frozen_string_literal: true

class PeerAssessment::RubricsController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper

  inside_course except: [:remove_option]

  before_action(except: [:index]) { authorize! 'peerassessment.peerassessment.edit' }
  before_action :set_tabs, except: [:remove_option]

  layout 'edit_peer_assessment_layout'
  # TODO: remove Acfs

  def index
    authorize! 'peerassessment.peerassessment.view'

    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id]) do |assessment|
      @rubrics = Xikolo::PeerAssessment::Rubric.where peer_assessment_id: assessment.id do |rubrics|
        @rubric_presenters = build_rubric_presenters rubrics
      end
      @assessment_presenter = PeerAssessment::PeerAssessmentEditPresenter.new(peer_assessment: assessment)
    end

    Acfs.run
  end

  def new
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id])
    @rubric = Xikolo::PeerAssessment::Rubric.new

    Acfs.run
  end

  def edit
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id])

    Xikolo::PeerAssessment::Rubric.find UUID(params[:id]), params: {raw: true} do |rubric|
      @rubric = PeerAssessment::RubricPresenter.create(rubric)
    end

    Acfs.run
  end

  def create
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id])

    Acfs.run

    # Create Rubric first
    rubric = Xikolo::PeerAssessment::Rubric.create! create_params.merge peer_assessment_id: params[:peer_assessment_id]

    # Now, create all its options
    params[:options].each do |option|
      new_option = Xikolo::PeerAssessment::RubricOption.new
      new_option.rubric_id = rubric.id
      new_option.description = option[1][:description]
      new_option.points = option[1][:points]

      new_option.save!
    end

    update_item(UUID(params[:peer_assessment_id]))

    add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.create_success')
    redirect_to peer_assessment_rubrics_path short_uuid(@assessment.id)
  end

  ### Positional edit actions ###

  # Moves the rubric up, which means that the student sees this rubric earlier
  def moveup
    load_rubric

    if @rubric.update_attributes params, params: {moveup: true}
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_failure')
    end

    redirect_to peer_assessment_rubrics_path
  end

  def movedown
    load_rubric

    if @rubric.save params: {movedown: true}
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.moved_failure')
    end

    redirect_to peer_assessment_rubrics_path
  end

  def remove_option
    @option = Xikolo::PeerAssessment::RubricOption.find params[:option_id]

    Acfs.run

    if @option.delete
      render json: {success: true}
    else
      render json: {success: false}
    end
  end

  def update
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:peer_assessment_id])

    Xikolo::PeerAssessment::Rubric.find UUID(params[:id]) do |rubric|
      @rubric = rubric
      rubric.options!
    end

    Acfs.run

    # First, update the rubric itself
    if @rubric.update_attributes update_params
      # Now, update all options
      params[:options].each do |option|
        if option[1].key? :id
          opt = @rubric.options!.detect {|o| o.id == option[1][:id] }
        else
          # New rubric option
          opt = Xikolo::PeerAssessment::RubricOption.new
          opt.rubric_id = @rubric.id
        end

        opt.description = option[1][:description]
        opt.points = option[1][:points]

        opt.save!
      end

      update_item(UUID(params[:peer_assessment_id]))

      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.update_success')
      redirect_to peer_assessment_rubrics_path short_uuid(@assessment.id)
    else
      add_flash_message :error, I18n.t(:'peer_assessment.administration.rubrics.update_failure')
      redirect_to edit_peer_assessment_rubric_path short_uuid(@assessment.id), short_uuid(@rubric.id)
    end
  end

  def destroy
    load_rubric

    if @rubric.delete
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.destroy_success')
    else
      add_flash_message :success, I18n.t(:'peer_assessment.administration.rubrics.destroy_failure')
    end

    redirect_to peer_assessment_rubrics_path
  end

  def hide_course_nav?
    true
  end

  private

  def options!(id)
    @options ||= pa_api.rel(:rubric_options).get(rubric_id: id).value!
  end

  def update_item(peer_assessment_id)
    # Reload the peer assessment and update its item to reflect the new points
    Xikolo::PeerAssessment::PeerAssessment.find peer_assessment_id do |assessment|
      Xikolo::Course::Item.find assessment.item_id do |item|
        item.max_points = assessment.max_points
        item.save
      end
    end

    Acfs.run
  end

  def set_tabs
    @active_tab = :rubrics
  end

  def create_params
    params.require(:xikolo_peer_assessment_rubric).permit :title, :hints
  end

  def update_params
    params.require(:xikolo_peer_assessment_rubric).permit :title, :hints
  end

  def load_rubric
    @rubric = Xikolo::PeerAssessment::Rubric.find UUID(params[:id])
    Acfs.run
  end
end
