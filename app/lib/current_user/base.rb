# frozen_string_literal: true

module CurrentUser
  class Base
    def initialize(context_id:)
      @context_id = context_id
    end

    def id
      user.id
    end

    def name
      user.name
    end

    def email
      user.primary_email&.address
    end

    def allowed?(name)
      permissions.include?(name)
    end

    def authenticated?
      !anonymous?
    end
    alias logged_in? authenticated?

    def instrumented? = masqueraded?

    def allowed_any?(*names)
      permissions.intersect?(names)
    end

    def preferences
      user.preferences.with_indifferent_access
    end

    def preferred_language
      user.language
    end

    def feature?(name)
      name = name.to_s.downcase
      return feature_memo[name] if feature_memo.key?(name)

      feature_memo[name] = AccountService::Feature.lookup(owner: user, context:)
        .where(name:).any?
    end

    private

    def permissions
      @permissions ||= AccountService::Role.permissions(principal: user, context:)
    end

    def feature_memo
      @feature_memo ||= {}
    end

    def context
      @context ||= if @context_id
                     AccountService::Context.resolve(@context_id)
                   else
                     AccountService::Context.root
                   end
    end
  end
end
