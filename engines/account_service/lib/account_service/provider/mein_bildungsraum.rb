# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class MeinBildungsraum < SAML
    def data
      {
        email: "#{uid}@example.com",
        full_name: 'Mein Bildungsraum User',
        confirmed: false,
      }
    end

    def create
      User::Create.new(data).call.tap do |user|
        authorization.update!(user:)
        # Do not send a welcome mail.
      end
    end

    def update(user)
      # Do not confirm the email as implemented in `Provider::Saml#update`.
      # Thus, no notifications are sent.
    end
  end
end
end
