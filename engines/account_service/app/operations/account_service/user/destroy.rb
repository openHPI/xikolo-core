# frozen_string_literal: true

module AccountService
class User::Destroy < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  def call(user)
    user.transaction do
      user.authorizations.destroy_all
      user.emails.destroy_all
      user.password_resets.destroy_all
      user.sessions.destroy_all
      user.tokens.destroy_all

      teacher = CourseService::Teacher.find_by(user_id: user.id)

      if teacher
        teacher.update!(
          name: 'Anonymized Teacher',
          description: {'de' => 'Anonymisierter Lehrer', 'en' => 'Anonymized teacher'},
          picture_uri: nil
        )

        remove_avatar_images!(teacher)
      end

      user.update! archived: true,
        full_name: 'Deleted User',
        display_name: 'Deleted User',
        born_at: nil,
        country: nil,
        state: nil,
        city: nil,
        gender: nil,
        status: nil,
        avatar_uri: nil,
        confirmed: false

      if ENV.key?('XIKOLO_WEB_API')
        CodeOceanUserDeletionJob.perform_later(user.id)
      end

      remove_avatar_images!(user)
    end

    user.reload
  end

  private

  def remove_avatar_images!(user)
    bucket = Xikolo::S3.bucket_for(:avatars)
    # request list of objects
    uid = UUID4(user.id).to_str(format: :base62)
    bucket.objects(prefix: "avatars/#{uid}").each do |obj|
      obj.delete
    rescue Aws::S3::Errors::ServiceError => e
      ::Sentry.capture_exception(e)
    end
  rescue Aws::S3::Errors::ServiceError => e
    ::Sentry.capture_exception(e)
  end
end
end
