# frozen_string_literal: true

class PollsController < Abstract::FrontendController
  before_action :set_no_cache_headers
  before_action :ensure_logged_in

  def archive
    @polls = Poll::Poll.includes(:options).started.latest_first.take(20)
      .map { PollArchivePresenter.new(_1, current_user) }
  end

  def next
    poll = Poll::Poll.upcoming_for_user(current_user.id).first!

    render Dashboard::Poll::Widget.new(poll).with_content(
      Dashboard::Poll::Question.vote(poll).render_in(view_context)
    ), layout: false
  rescue ActiveRecord::RecordNotFound
    head :no_content
  end

  def vote
    poll = Poll::Poll.find(params[:id])
    response = poll.vote! choices, user_id: current_user.id

    has_next_poll = Poll::Poll.upcoming_for_user(current_user.id).exists?

    render Dashboard::Poll::Widget.new(poll).with_content(
      Dashboard::Poll::Thanks.new(
        poll,
        choices: response.choices,
        stats: poll.reveal_results? ? poll.stats : nil,
        next_poll: has_next_poll
      ).render_in(view_context)
    ), layout: false
  end

  private

  def choices
    Array.wrap params.require(:poll)
  end
end
