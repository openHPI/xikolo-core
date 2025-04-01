# frozen_string_literal: true

module Resources
  class Receiver
    def self.load_by_id(id)
      @account_api ||= Xikolo.api(:account).value!
      new @account_api.rel(:user).get({id:}).value!
    end

    def initialize(resource)
      @resource = resource
    end

    def notify?(type, default: true)
      return false unless notify_global?

      # Start loading preferences and features in parallel
      preferences
      features

      preferences.value!.get_bool("notification.email.#{notify_key(type)}", default:)
    end

    def notify_global?
      return false if archived
      return false unless email

      preferences.value!.get_bool('notification.email.global', default: true) &&
        !features.value!.key?('primary_email_suspended')
    end

    def disable_links(type)
      email = email_resource.value!
      email_hash = Digest::SHA256.hexdigest [email['id'], id].join

      link = Addressable::URI.parse Xikolo.base_url.join('notification_user_settings/disable')
      link.query_values = {'email' => self.email, 'hash' => email_hash, 'key' => 'global'}

      {
        disable_link_global: link.to_s,
      }.tap do |links|
        next unless (key = settings_key(type))

        link.query_values = link.query_values.merge 'key' => key
        links[:disable_link_local] = link.to_s
      end
    end

    def id
      @resource['id']
    end

    def name
      @resource['name']
    end

    def full_name
      @resource['full_name']
    end

    def email
      @resource['email']
    end

    def language
      @resource['language']
    end

    def archived
      @resource['archived']
    end

    def created_at
      DateTime.parse @resource['created_at']
    end

    def preferences
      @preferences ||= @resource.rel(:preferences).get.then do |p|
        Preferences.new @resource, p['properties']
      end
    end

    def features
      @features ||= @resource.rel(:features).get.then do |f|
        Features.new f
      end
    end

    private

    def email_resource
      @email_resource ||= @resource.rel(:emails).get.then(&:first)
    end

    # Map notification types to correct preference keys, if necessary.
    # For historic reasons, new_post used a wrong key, so pinboard.new_answer
    # should apply for all forum posts.
    def notify_key(type)
      {
        'pinboard.new_thread' => 'pinboard.new_answer',
        'pinboard.new_post' => 'pinboard.new_answer',
      }.fetch(type, type)
    end

    # The keys used for communicating the type of email to disable to xi-web
    # use yet another mapping than the preferences stored in xi-account. :(
    def settings_key(key)
      {
        'news.announcement' => 'announcement',
        'course.announcement' => 'course_announcement',
        'pinboard.new_thread' => 'pinboard',
        'pinboard.new_post' => 'pinboard',
      }[key]
    end
  end
end
