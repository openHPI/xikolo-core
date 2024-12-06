# frozen_string_literal: true

class SubmissionStatisticsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json

  def show
    if (embed - supported_statistics).present?
      unsupported_statistic_error
      return
    end

    if only.present? && supported_statistics.exclude?(only)
      unsupported_statistic_error
      return
    end

    quiz = Quiz.find(params[:id])

    respond_with quiz.stats
  end

  def decoration_context
    {
      embed:,
      only:,
    }
  end

  private

  def supported_statistics
    %w[
      avg_submit_duration
      submissions_over_time
      box_plot_distributions
      questions_base_stats
      questions
    ]
  end

  def unsupported_statistic_error
    render json: {
      error: "Supported statistics are: #{supported_statistics.join(', ')}",
      status: 404,
    }, status: :not_found
  end

  def embed
    params[:embed].to_s.split(',').map(&:strip)
  end

  def only
    params[:only].to_s.strip
  end
end
