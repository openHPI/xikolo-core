# frozen_string_literal: true

module Navigation
  class ProfileItemPreview < ViewComponent::Preview
    def default
      render Navigation::ProfileItem.new(user: registered_user, gamification_score: nil)
    end

    def instrumented
      render Navigation::ProfileItem.new(user: instrumented_user, gamification_score: nil)
    end

    def with_gamification
      render Navigation::ProfileItem.new(user: gamified_user, gamification_score: 100)
    end

    private

    USER_ID = SecureRandom.uuid
    private_constant :USER_ID

    def registered_user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user_id' => USER_ID,
        'user' => {'anonymous' => false},
      })
    end

    def instrumented_user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'user_id' => USER_ID,
        'user' => {'anonymous' => false},
        'masqueraded' => true,
      })
    end

    def gamified_user
      Xikolo::Common::Auth::CurrentUser.from_session({
        'features' => {'gamification' => true},
        'user_id' => USER_ID,
        'user' => {'anonymous' => false},
      })
    end
  end
end
