# frozen_string_literal: true

module Global
  class HelpdeskButton < ApplicationComponent
    ##
    # Specify the available chatbot versions here.
    # Format: feature flipper name => version identifier
    # Attention: The order of the versions is important.
    # The first matching feature / version is displayed to the user.
    CHATBOT_VERSION = {
      'chatbot.prototype-2' => 'chatbot-v2',
    }.freeze

    def initialize(user:)
      @user = user
    end

    def icon
      Global::FaIcon.new(chatbot.present? ? 'messages' : 'message-question', style: :solid)
    end

    def data_feature
      chatbot.presence || 'default'
    end

    private

    def chatbot
      @chatbot ||= CHATBOT_VERSION.keys
        .detect { @user.feature? it }
        .then { CHATBOT_VERSION[it] }
    end
  end
end
