# frozen_string_literal: true

module NewsService
class EmailsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  ##
  # Send an announcement email to one or more receivers
  #
  def create
    announcement = News.find(params[:announcement_id])
    announcement.emails.create!(
      test_recipient: params[:test_receiver]
    )

    render json: {}, status: :created
  end
end
end
