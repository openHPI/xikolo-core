# frozen_string_literal: true

module AccountService
class User::Destroy < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  include Facets::Tracing

  def call(user)
    user.transaction do
      user.authorizations.destroy_all
      user.emails.destroy_all
      user.password_resets.destroy_all
      user.sessions.destroy_all
      user.tokens.destroy_all

      user.update! archived: true,
        full_name: 'Deleted User',
        display_name: 'Deleted User',
        avatar_uri: nil,
        confirmed: false

      CustomFieldValue.where(context: user).destroy_all
    end

    remove_avatar_images!(user)

    user
  end

  private

  def remove_avatar_images!(user)
    bucket = Xikolo::S3.bucket_for(:avatars)
    # request list of objects
    uid = UUID4(user.id).to_str(format: :base62)
    bucket.objects(prefix: "avatars/#{uid}").each do |obj|
      obj.delete
    rescue Aws::S3::Errors::ServiceError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
    end
  rescue Aws::S3::Errors::ServiceError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
  end
end
end
