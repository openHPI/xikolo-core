# frozen_string_literal: true

# TODO: Refactor without the issues disabled here
# rubocop:disable Rails/HelperInstanceVariable

module PeerAssessment::AssessmentStepHelper
  # Determines if a certain action (inside of a step) is allowed to be executed
  def check_step_validity
    # Validity criteria:
    #   1. Open or finished state
    #   2. Current_step and current_step >= selected_step
    #   3. Participant exists ('visit' indicator)
    #   4. If there is an unlock date, check if accessible

    Acfs.on the_steps, the_participant do |_, participant|
      next unless @current_step && params[:mode] != 'teacherview'

      if participant.nil? || !participant.current_step
        # User tried to access a specific step without starting or visiting the peer assessment
        raise Status::Redirect.new 'Step not accessible', peer_assessment_path(short_uuid(the_assessment.id))
      end

      # Step the user clicked on / has been redirected to
      @selected_step = @current_step

      # Latest step that is accessible for the user
      @active_step = @step_presenters.find {|e| e.id == @participant.current_step }

      # User tries to access a step he did not explicitly advance to
      if @active_step.position < @selected_step.position
        if (@selected_step.position - @active_step.position) == 1 && @active_step.optional
          # redirect_to skip_peer_assessment_step_path(@assessment.id, @current_step.id)
          # Decision whether to advance or skip will be made in the peer assessment service
          redirect_to advance_peer_assessment_step_path(@assessment.id, @current_step.id)
        else
          add_flash_message :error, I18n.t(:'peer_assessment.step.inaccessible')
          raise Status::Redirect.new(
            'Step not accessible',
            peer_assessment_step_path(the_assessment.id, short_uuid(@active_step.id))
          )
        end
      end

      # User tries to access a step, which is not open (locked or otherwise inaccessible)
      if !@selected_step.open? && !@selected_step.finished?

        # Tries to access a locked step
        if @selected_step.unlock_date&.future?
          handle_step_locked
        end

        # Tries to access a step with a passed deadline
        if @selected_step.deadline.past?
          handle_deadline_passed
        end
      end
    end
  end

  def handle_deadline_passed
    raise Status::Redirect.new 'Step deadline passed',
      deadline_passed_peer_assessment_step_path(the_assessment.id, short_uuid(@active_step.id))
  end

  def handle_step_locked
    raise Status::Redirect.new 'Step not unlocked',
      locked_peer_assessment_step_path(the_assessment.id, short_uuid(@active_step.id))
  end
end

# rubocop:enable all
