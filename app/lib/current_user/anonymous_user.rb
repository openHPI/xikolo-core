# frozen_string_literal: true

module CurrentUser
  class AnonymousUser < Base
    def id
      'anonymous'
    end

    def interrupts
      []
    end

    def anonymous?
      true
    end

    def masqueraded?
      false
    end

    private

    def user
      @user ||= AccountService::User.anonymous
    end
  end
end
