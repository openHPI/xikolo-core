# frozen_string_literal: true

module Accept
  extend ActiveSupport::Concern

  included do
    before_action :_adjust_accepts
  end

  private

  def _adjust_accepts
    # Always include formats from ACCEPT header
    mimes = [
      *request.formats, *request.accepts
    ].compact.uniq

    # if ACCEPT is not present, behave like */* is passed
    mimes << Mime::ALL if request.accepts.compact.empty?

    request.set_header 'action_dispatch.request.formats', mimes
  end
end
