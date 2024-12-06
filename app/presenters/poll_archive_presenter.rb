# frozen_string_literal: true

class PollArchivePresenter
  include Rails.application.routes.url_helpers

  def initialize(poll, current_user)
    @poll = poll

    @response = @poll.response_for(current_user.id)
  end

  delegate :id, :question, to: :@poll

  def show_results?
    return true if @poll.ended?

    voted? && @poll.reveal_results?
  end

  def results_info
    if @poll.open?
      I18n.t(:'polls.archive.intermediate_results', participants: num_participants)
    else
      I18n.t(:'polls.archive.final_results', date: end_at, participants: num_participants)
    end
  end

  def no_results_info
    if !voted?
      Global::Callout.new(I18n.t(:'polls.archive.place_vote', date: end_at, link: dashboard_path))
    elsif !@poll.show_intermediate_results?
      Global::Callout.new(I18n.t(:'polls.archive.not_ended', date: end_at))
    elsif !@poll.enough_participants?
      Global::Callout.new(I18n.t(:'polls.archive.not_enough_participants'))
    end
  end

  def results
    Dashboard::Poll::Question.results(@poll, stats: @poll.stats, choices: @response&.choices)
  end

  private

  def voted?
    @response.present?
  end

  def end_at
    I18n.l(@poll.end_at.to_date, format: :short)
  end

  def num_participants
    ActionController::Base.helpers.number_with_delimiter(@poll.stats.participants)
  end
end
