# frozen_string_literal: true

module WellKnown
  class FilesController < ApplicationController
    def show
      file = WellKnownFile.find(params[:filename])

      expires_in 1.hour, public: true

      # Skip rendering if we can respond with a 304 Not Modified because ETag or
      # If-Modified-Since header values match.
      fresh_when(file) || render(plain: file.content)
    rescue ActiveRecord::RecordNotFound
      # If the requested file can not be found, we behave like a non-existing
      # controller action so that our 404 error handler can kick in.
      raise AbstractController::ActionNotFound
    end
  end
end
