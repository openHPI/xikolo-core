# frozen_string_literal: true

class Admin::PollOptionsController < Abstract::AjaxController
  require_permission 'helpdesk.polls.manage'

  before_action do
    head :unprocessable_entity unless poll.editing_allowed?
  end

  def create
    poll.add_option(option_params)

    render partial: 'admin/polls/options_form',
      locals: {
        poll:,
        options: poll.options,
      }
  end

  def destroy
    poll.options.delete(params[:id])

    render partial: 'admin/polls/options_form',
      locals: {
        poll:,
        options: poll.options,
      }
  end

  private

  def poll
    @poll ||= Poll::Poll.find params[:poll_id]
  end

  def option_params
    params.permit(:text)
  end
end
