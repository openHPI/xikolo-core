# frozen_string_literal: true

module CurrentUser
  class User < Base
    attr_reader :session

    def initialize(context_id:, session:)
      @session = session

      super(context_id:)
    end

    def interrupts
      session.interrupts
    end

    def anonymous?
      false
    end

    def masqueraded?
      session.masqueraded?
    end

    private

    def user
      session.effective_user
    end
  end
end
