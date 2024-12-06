# frozen_string_literal: true

module With
  class << self
    # Around function to enable or disable the
    # ActiveRecord CSRF protection. It defaults
    # to enable CSRF protection, because CRSF protection
    # usually is disabled in test environment.
    #
    # The old value will be restored after the test.
    #
    # To be used with `Kernel#With`.
    #
    # Example:
    #   around(&With(:csrf_protection, true))
    #
    #   it 'triggered CSRF protection' do
    #     expect { post '/action' }.to \
    #       raise(ActionController::InvalidAuthenticityToken)
    #   end
    #
    def csrf_protection(allow)
      old = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = allow

      yield
    ensure
      ActionController::Base.allow_forgery_protection = old
    end
  end
end

module Kernel
  # This functions allow to create a simple yieldable
  # around hook based on module functions in `With`.
  #
  # Example:
  #   around(&With(:csrf_protection, false))
  #
  # This will call `With.csrf_protection` with the given values
  # and the example as a yieldable block.
  #
  def With(name, *) # rubocop:disable Naming/MethodName
    ->(example) { With.method(name).call(*, &example) }
  end
end
