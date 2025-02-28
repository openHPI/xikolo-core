# frozen_string_literal: true

module Dashboard
  class IcalFeedPreview < ViewComponent::Preview
    def default
      render Dashboard::IcalFeed.new(user: user)
    end

    private

    def user
      Xikolo::Common::Auth::CurrentUser.from_session({'features' => {'ical_feed' => true},
                                                       'user_id' => SecureRandom.uuid,
                                                       'user' => {'anonymous' => false}})
    end
  end
end
