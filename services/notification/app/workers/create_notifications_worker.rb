# frozen_string_literal: true

class CreateNotificationsWorker
  include Sidekiq::Job
  include Notify

  def perform(event_id, subscriber_ids)
    event = make_event event_id, subscriber_ids

    # Create platform notifications for all users
    event.notify!

    # ...and send out emails to the appropriate recipients
    if event.send_mail?
      notify_all event.mail_recipients, event.mail_template, event.mail_payload
    end
  end

  private

  def make_event(id, subscriber_ids)
    model = Event.find id

    if model.collab_space_id.present?
      CollabSpaceEvent.new model, subscriber_ids
    else
      NormalEvent.new model, subscriber_ids
    end
  end

  class NormalEvent
    def initialize(event, subscriber_ids)
      @model = event
      @subscriber_ids = subscriber_ids
    end

    def notify!
      @model.notifications = @subscriber_ids.map do |subscriber|
        Notification.new user_id: subscriber
      end
    end

    def send_mail?
      @model.send_mail?
    end

    def mail_recipients
      # Don't send a mail to the user who caused this event
      @subscriber_ids.reject {|user| user == @model.payload['user_id'] }
    end

    def mail_template
      @model.mail_template
    end

    def mail_payload
      @model.mail_payload
    end
  end

  class CollabSpaceEvent
    def initialize(event, subscriber_ids)
      @model = event
      @subscriber_ids = subscriber_ids
    end

    def notify!
      @model.notifications = subscribers.map do |subscriber|
        Notification.new user_id: subscriber
      end
    end

    def send_mail?
      @model.send_mail?
    end

    def mail_recipients
      # Don't send a mail to the user who caused this event
      (team? ? subscribers : @subscriber_ids).reject do |user|
        user == @model.payload['user_id']
      end
    end

    def mail_template
      @model.mail_template
    end

    def mail_payload
      @model.mail_payload
    end

    private

    def subscribers
      @subscribers ||= collab_space_subscribers
    end

    def team?
      Xikolo.api(:collabspace).value!.rel(:collab_space).get({id: @model.collab_space_id}).value!['kind'] == 'team'
    end

    # Events in a collab space are sent to all its members plus all course admins
    def collab_space_subscribers
      members = Xikolo.api(:collabspace).value!.rel(:memberships).get({
        collab_space_id: @model.collab_space_id,
      }).value!.map(&:user_id)

      course_code = Xikolo.api(:course).value!.rel(:course).get({id: @model.course_id}).value!['course_code']

      # TODO: Get other users by permission, not by group
      admins = Xikolo.api(:account).value!.rel(:group).get({id: "course.#{course_code}.admins"}).then do |group|
        group.rel(:members).get
      end

      members.concat Array.wrap(admins.value).map(&:id)
      members.uniq
    end
  end
end
