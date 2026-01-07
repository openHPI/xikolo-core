# frozen_string_literal: true

require 'markdown_service'

# Preview all emails at http://localhost:3200/rails/mailers/notification
class NotificationPreview < ActionMailer::Preview
  def pinboard_new_post
    NotificationService::NotificationMailer.notification(
      receiver,
      'pinboard.new_post',
      {
        user_id: receiver.id,
        username: receiver.name,
        user_name: receiver.name,
        topic_id: SecureRandom.uuid,
        topic_title: 'What do you think?',
        thread_title: 'What do you think?',
        topic_author_id: receiver.id,
        comment_id: SecureRandom.uuid,
        text: 'What a great post.',
        html: MarkdownService.render_html('What a great post.'),
        course_code: 'elearning101',
        course_name: 'All about online teaching',
        answer_author_name: 'Rüdiger',
        timestamp: 1.minute.ago.to_s,
        link: Xikolo.base_url.join('pinboard/post').to_s,
      }
    )
  end

  def pinboard_new_thread
    NotificationService::NotificationMailer.notification(
      receiver,
      'pinboard.new_thread',
      {
        user_name: receiver.name,
        thread_title: 'What do you think?',
        text: 'What a great day for a new thread.',
        html: MarkdownService.render_html('What a great day for a new thread.'),
        course_name: 'All about online teaching',
        timestamp: 1.minute.ago.to_s,
        link: Xikolo.base_url.join('pinboard/post').to_s,
      }
    )
  end

  def pinboard_blocked_item
    NotificationService::NotificationMailer.notification(
      receiver,
      'pinboard.blocked_item',
      {
        item_url: 'https://www.example.com',
      }
    )
  end

  def course_announcement
    NotificationService::NotificationMailer.notification(
      receiver,
      'course.announcement',
      {
        text: 'This is a course announcement',
        course_title: 'Course title',
      }
    )
  end

  def news_announcement
    NotificationService::NotificationMailer.notification(
      receiver,
      'news.announcement',
      {
        text: 'News',
        course_title: 'Course title',
        site_name: 'Site name',
      }
    )
  end

  private

  def receiver
    @receiver ||= NotificationService::Resources::Receiver.new({
      'id' => SecureRandom.uuid,
      'name' => 'Peer Previewer',
      'email' => 'previewer@example.de',
      'language' => 'en',
    })
  end
end
