# frozen_string_literal: true

require 'token_signing'

Rails.application.reloader.to_prepare do
  if Rails.application.secrets.chatbot_bridge_private_key
    TokenSigning.register(
      :chatbot,
      sign: TokenSigning::Paseto::Sign.new(Rails.application.secrets.chatbot_bridge_private_key),
      verify: TokenSigning::VerifyMultiple.new(
        *Xikolo.config.chatbot['bridge_public_keys'].map do |key|
          TokenSigning::Paseto::Verify.new(key)
        end
      )
    )
  end
end
