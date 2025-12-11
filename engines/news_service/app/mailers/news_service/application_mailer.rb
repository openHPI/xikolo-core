# frozen_string_literal: true

module NewsService
class ApplicationMailer < ActionMailer::Base # rubocop:disable Layout/IndentationWidth
  layout 'news_service/foundation'

  private

  # Hook mail call to add inline attachment of brand specific
  # logo if it exist
  def mail(*args)
    args[0][:from] = Xikolo.config.mailsender

    super
  end
end
end
