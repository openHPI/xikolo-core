# frozen_string_literal: true

module NewsService
class ApplicationMailer < ActionMailer::Base # rubocop:disable Layout/IndentationWidth
  prepend_view_path "brand/#{Xikolo.brand}/views"
  layout 'foundation'

  private

  # Hook mail call to add inline attachment of brand specific
  # logo if it exist
  def mail(*args)
    args[0][:from] = Xikolo.config.mailsender

    super
  end
end
end
