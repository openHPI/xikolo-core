# frozen_string_literal: true

module PeerAssessment::PeerAssessmentContextHelper
  def self.included(base_controller)
    return unless base_controller.respond_to? :before_action

    class << base_controller
      def inside_assessment(**)
        before_action(:load_participant, **)
        before_action(:load_assessment, **)
        before_action(:load_workflow_data, **)
        before_action(:check_step_validity, **)
      end

      def inside_assessment_skip_checks(**)
        before_action(:load_participant, **)
        before_action(:load_assessment, **)
        before_action(:load_workflow_data, **)
      end
    end
  end

  def set_pa_id
    @pa_id = UUID4.try_convert(params[:peer_assessment_id]).to_s
  end

  def pa_api
    @pa_api ||= Xikolo.api(:peerassessment).value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def load_peer_assessment
    @assessment = pa_api.rel(:peer_assessment).get(id: @pa_id).value!
  end

  # deprecated
  def load_assessment
    @assessment = the_assessment
  end

  def load_participant
    @participant = the_participant
  end

  def load_training_step
    Acfs.on the_assessment do |assessment|
      @training_step = Xikolo::PeerAssessment::Training.find_by(
        type: 'Training',
        peer_assessment_id: assessment.id
      )
    end
  end

  def short_uuid(id)
    UUID(id).to_param
  end

  # Here, workflow steps are loaded and marked with their respective state for
  # the requesting user (finished, locked, ...)
  def load_workflow_data
    @step_presenters = []
    @potential_result_swal = false

    Acfs.on the_steps, the_participant do |steps|
      steps.each do |step|
        presenter = PeerAssessment::StepPresenter.build(step)
        @step_presenters << presenter

        # If there is no self assessment step, there should never be a sweet
        # alert on the results step
        @potential_result_swal = true if presenter.step.is_a? Xikolo::PeerAssessment::SelfAssessment

        # Set the current step for easier step handling
        next unless (UUID(step.id) == UUID(params[:id])) || (UUID(step.id) == UUID(params[:step_id]))

        @current_step = presenter
        next if @current_step.nil?

        @inside_submission = @current_step.step.is_a? Xikolo::PeerAssessment::AssignmentSubmission
        @inside_training = @current_step.step.is_a? Xikolo::PeerAssessment::Training
        @inside_self_assessment = @current_step.step.is_a? Xikolo::PeerAssessment::SelfAssessment
        @inside_results = @current_step.step.is_a? Xikolo::PeerAssessment::Results
        @potential_result_swal = false if @inside_results
      end

      mark_steps
    end
  end

  # Mark all presenters up to the current step as finished, mark all others as
  # locked or open.
  #
  def mark_steps
    current_step_position = @step_presenters.index {|el| el.id == @participant.try(:current_step) }

    @step_presenters.each_with_index do |presenter, index|
      # Assessment not yet started
      unless current_step_position
        # Open == true ==> unlock date past and deadline future
        if (index == 0) && presenter.open
          presenter.state = :open
        else
          presenter.state = :locked
        end

        next
      end

      if index == current_step_position
        # The step the user currently works on
        if @participant.completion.to_d == BigDecimal('1.0')
          presenter.state = :finished
        elsif presenter.open
          presenter.state = :open
        else
          presenter.state = :locked

          if presenter.deadline.past?
            case presenter.step # rubocop:disable Metrics/BlockNesting
              when Xikolo::PeerAssessment::Training
                @training_passed = true
              when Xikolo::PeerAssessment::SelfAssessment
                @self_assessment_passed = true
            end
          end
        end
      elsif index < current_step_position
        # Everything before the current step must be finished
        presenter.state = :finished
        @training_finished = true if presenter.step.is_a? Xikolo::PeerAssessment::Training
        @potential_result_swal = false if presenter.step.is_a? Xikolo::PeerAssessment::SelfAssessment
      elsif (index == (current_step_position + 1)) &&
            ((@participant.completion.to_d == BigDecimal('1.0')) || @step_presenters[current_step_position].optional) &&
            presenter.open

        # The current step is finished and the next step is open
        presenter.state = :open
      else
        presenter.state = :locked
      end

      # Extra handling for the last step, since it is slightly different than
      # the other steps (it does not really require the user to do anything)
      if presenter.deadline.to_datetime.past? && (@step_presenters.last == presenter)
        presenter.state = :finished
      end
    end
  end

  # Determines what is the next action for the given step class
  def determine_step_redirect(step_presenter)
    case step_presenter.step
      when Xikolo::PeerAssessment::AssignmentSubmission
        # Redirect to Submission#new if not finished, show the submission
        # otherwise
        if step_presenter.finished?
          peer_assessment_step_submission_url(
            short_uuid(the_assessment.id),
            short_uuid(step_presenter.id)
          )
        else
          new_peer_assessment_step_submission_url(
            short_uuid(the_assessment.id),
            short_uuid(step_presenter.id)
          )
        end

      when Xikolo::PeerAssessment::Training
        # training_overview_peer_assessment_step_reviews_url
        # short_uuid(the_assessment.id), short_uuid(step_presenter.id)
        evaluate_peer_assessment_step_training_index_path(
          short_uuid(the_assessment.id),
          short_uuid(step_presenter.id)
        )

      when Xikolo::PeerAssessment::PeerGrading
        # Show always the overview
        peer_assessment_step_reviews_url(
          short_uuid(the_assessment.id),
          short_uuid(step_presenter.id)
        )

      when Xikolo::PeerAssessment::SelfAssessment
        # Redirect to SelfAssessment#new if not finished, show the self
        # assessment otherwise
        if step_presenter.finished?
          peer_assessment_step_self_assessments_path(
            short_uuid(the_assessment.id),
            short_uuid(step_presenter.id)
          )
        else
          new_peer_assessment_step_self_assessments_path(
            short_uuid(the_assessment.id),
            short_uuid(step_presenter.id)
          )
        end

      when Xikolo::PeerAssessment::Results
        # Always the index page, which serves as the general overview page
        peer_assessment_step_results_path(
          short_uuid(the_assessment.id),
          short_uuid(step_presenter.id)
        )

      else
        raise TypeError
    end
  end

  def sort_options
    [
      [t(:'peer_assessment.submission_management.average_sort'), :points],
      [t(:'peer_assessment.submission_management.average_rating'), :avg_rating],
      [t(:'peer_assessment.submission_management.nominations'), :nominations],
    ]
  end

  def team_options(course_id)
    options = []
    Xikolo.paginate(
      Xikolo.api(:collabspace).value!.rel(:learning_rooms).get(
        kind: 'team',
        course_id:
      )
    ) do |collab_space|
      options << [collab_space.name, collab_space.name]
    end
    options
  end
end
