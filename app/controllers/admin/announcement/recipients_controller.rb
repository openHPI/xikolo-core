# frozen_string_literal: true

class Admin::Announcement::RecipientsController < Abstract::AjaxController
  require_feature 'admin_announcements'

  def index
    authorize! 'news.announcement.send'

    users = Rails.cache.fetch(
      "announcements/users/#{params[:q]}",
      expires_in: 30.minutes,
      race_condition_ttl: 10.seconds
    ) do
      account_service.rel(:users).get({query: params[:q]}).value!
    end

    user_recipients = users.map do |user|
      {
        group: I18n.t('admin.announcement_email.recipients_selector_students'),
        id: "user:#{user['id']}",
        text: "#{user['name']} (#{user['email']})",
      }
    end

    courses = Rails.cache.fetch(
      "announcements/courses/#{params[:q]}",
      expires_in: 1.hour,
      race_condition_ttl: 10.seconds
    ) do
      Xikolo.api(:course).value!.rel(:courses).get({
        groups: 'any',
        autocomplete: params[:q],
        limit: 100,
      }).value!
    end

    course_recipients = courses.map do |course|
      {
        group: I18n.t('admin.announcement_email.recipients_selector_courses'),
        id: "group:course.#{course['course_code']}.students",
        text: I18n.t('admin.announcement_email.recipients_course_students',
          course: course['title'], course_code: course['course_code']),
      }
    end

    groups = Rails.cache.fetch(
      'announcements/groups/access',
      expires_in: 1.hour,
      race_condition_ttl: 10.seconds
    ) do
      account_service.rel(:groups).get({tag: 'access'}).value!
    end

    access_groups = groups.map do |group|
      {
        group: I18n.t('admin.announcement_email.recipients_selector_special_group'),
        id: "group:#{group['name']}",
        text: group['description'],
      }
    end

    content_test_groups = Rails.cache.fetch(
      "announcements/content_test_groups/#{params[:q]}",
      expires_in: 30.minutes,
      race_condition_ttl: 10.seconds
    ) do
      account_service.rel(:groups).get({prefix: "course.#{params[:q]}", tag: 'content_test'}).value!
    end

    content_test_groups = content_test_groups.map do |group|
      {
        group: I18n.t('admin.announcement_email.recipients_selector_content_tests'),
        id: "group:#{group['name']}",
        text: group['name'],
      }
    end

    custom_recipients_groups = Rails.cache.fetch(
      'announcements/custom_recipients',
      expires_in: 30.minutes,
      race_condition_ttl: 10.seconds
    ) do
      account_service.rel(:groups).get({tag: 'custom_recipients'}).value!
    end

    custom_recipients_groups = custom_recipients_groups.map do |group|
      {
        group: I18n.t('admin.announcement_email.recipients_selector_custom_recipients'),
        id: "group:#{group['name']}",
        text: group['name'],
      }
    end

    render json: [access_groups, course_recipients, user_recipients, content_test_groups,
                  custom_recipients_groups].flatten
  end

  private

  def account_service
    @account_service ||= Xikolo.api(:account).value!
  end
end
