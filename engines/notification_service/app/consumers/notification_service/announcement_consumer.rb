# frozen_string_literal: true

require 'markdown_service'

module NotificationService
class AnnouncementConsumer < Msgr::Consumer # rubocop:disable Layout/IndentationWidth
  def create
    if payload[:test]
      Msgr.publish({
        key: announcement.key,
        receiver_id: test_receiver,
        payload: announcement.notify_params.except(:mail_log).merge(test: true),
      }, to: 'xikolo.notification.notify_announcement')
    else
      send!
    end
  end

  private
  def send!
    # On the first page, we're updating the count in the news service with an
    # estimate of expected recipients.
    announcement.update_count iterator.count if iterator.first_page?

    iterator.each do |user_id|
      MailLog.queue_if_unsent!(user_id:, news_id: announcement.id) do
        Msgr.publish({
          key: announcement.key,
          receiver_id: user_id,
          payload: announcement.notify_params,
        }, to: 'xikolo.notification.notify_announcement')
      end
    end

    if iterator.next_page
      # If there is still more work to do (we only load one page of users in
      # each audience implementation), we schedule ourselves again, but with an
      # additional parameter to start at the next page.
      publish(
        payload.merge(page: iterator.next_page),
        to: 'xikolo.news.announcement.create'
      )
    else
      # On the last page, we're updating the count in the news service with the
      # actual number of queued emails.
      announcement.update_count MailLog.where(news_id: announcement.id).count
    end
  end

  def announcement
    @announcement ||= if payload[:course_id].present?
                        CourseAnnouncement.new(
                          payload[:id], payload[:title], payload[:course_id]
                        )
                      else
                        GlobalAnnouncement.new(payload[:id], payload[:title])
                      end
  end

  def audience
    @audience ||= if payload[:course_id].present?
                    Audience::AllCourseEnrollments.new(payload[:course_id])
                  elsif payload[:group].present?
                    Audience::UserGroup.new payload[:group]
                  else
                    Audience::AllConfirmedUsers.new
                  end
  end

  def iterator
    # Once we reach the second page, this iterator will use the URL provided in
    # the second parameter. Otherwise, it will start iteration based on what
    # the audience suggests. In any case, the audience will properly extract
    # the user ID from the response payloads.
    @iterator ||= Audience::Iterator.new(audience, payload[:page])
      .then do |iterator|
        # With the `require_enrollment` config enabled, we do not send global
        # announcements to users that have not yet enrolled to any course.
        if Xikolo.config.announcements['require_enrollment'] && payload[:course_id].blank?
          Audience::HasEnrolledOnce.new(iterator)
        else
          iterator
        end
      end
  end

  def test_receiver
    payload.fetch(:receiver_id, payload[:author_id])
  end

  class GlobalAnnouncement
    def initialize(news_id, title)
      @news_id = news_id
      @title = title
    end

    def update_count(count)
      Msgr.publish(
        {news_id: id, sending_state: 0, state: 'sending', receivers: count},
        to: 'xikolo.news.update_status'
      )
    end

    def id
      @news_id
    end

    def key
      'news.announcement'
    end

    def notify_params
      @notify_params ||= {
        subject: @title,
        title: @title,
        test: false,
        news_id: @news_id,
        link:,
        tracking_id: short_id,
        tracking_type: 'news',
        mail_log: true,
      }
    end

    protected

    def link
      "/news/#{short_id}"
    end

    def short_id
      UUID4(id).to_str(format: :base62)
    end
  end

  class CourseAnnouncement < GlobalAnnouncement
    def initialize(news_id, title, course_id)
      super(news_id, title)

      @course_id = course_id
    end

    def key
      'course.announcement'
    end

    def notify_params
      @notify_params ||= super.then do |params|
        params.merge(
          course_title: course['title'],
          subject: translated_subjects(params[:subject]),
          course_code: course['course_code'],
          course_id: course['id'],
          tracking_course_id: course['id']
        )
      end
    end

    protected

    def link
      "/courses/#{course['course_code']}/announcements/#{short_id}"
    end

    def translated_subjects(subject)
      subject.transform_values do |text|
        "#{text}: #{course['title']}"
      end
    end

    def course
      @course ||= course_api.rel(:course).get({
        id: @course_id,
      }).value!
    end

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end

  module Audience
    class AllConfirmedUsers
      def to_s
        account_api.rel(:users)
          .expand({confirmed: true, per_page: 500})
      end

      def extract(resource)
        resource['id']
      end

      private

      def account_api
        @account_api ||= Xikolo.api(:account).value!
      end
    end

    class UserGroup
      def initialize(id)
        @id = id
      end

      def to_s
        group.rel(:members).expand(per_page: 2500)
      end

      def extract(resource)
        resource['id']
      end

      private

      def group
        @group ||= Xikolo.api(:account).value!.rel(:group).get({id: @id}).value!
      end
    end

    class AllCourseEnrollments
      def initialize(course_id)
        @course_id = course_id
      end

      def to_s
        course_api.rel(:enrollments)
          .expand({course_id: @course_id.to_s, per_page: 50})
      end

      def extract(resource)
        resource['user_id']
      end

      private

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end
    end

    class Iterator
      def initialize(audience, url = nil)
        @audience = audience
        @url = url || @audience.to_s

        @first_page = url.nil?
      end

      def count
        Restify.new(@audience.to_s).get({per_page: '1'}).value!
          .response.headers['X_TOTAL_PAGES'].to_i
      end

      def each
        @response = Restify.new(@url).get.value!

        @response.each do |resource|
          yield @audience.extract(resource)
        end
      end

      def first_page?
        @first_page
      end

      def next_page
        @response.rel(:next).to_s if @response&.rel?(:next)
      end
    end

    class HasEnrolledOnce
      def initialize(iterator)
        @iterator = iterator
      end

      def count
        @iterator.count
      end

      def each
        @iterator.each do |user_id|
          yield user_id if enrolled_once?(user_id)
        end
      end

      def first_page?
        @iterator.first_page?
      end

      def next_page
        @iterator.next_page
      end

      private

      def enrolled_once?(user_id)
        course_api.rel(:enrollments)
          .get({deleted: true, user_id:, per_page: 1}).value!
          .any?
      end

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end
    end

    class TestMail
      def initialize(receiver_id)
        @receiver_id = receiver_id
      end

      def count
        1
      end

      def each
        yield @receiver_id
      end

      def first_page?
        true
      end

      def next_page
        nil
      end
    end
  end
end
end
