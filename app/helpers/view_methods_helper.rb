# frozen_string_literal: true

module ViewMethodsHelper
  include ActionView::Helpers

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def self.included(klazz)
    klazz.extend SanitizeHelper::ClassMethods
  end
end
