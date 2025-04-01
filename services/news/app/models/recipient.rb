# frozen_string_literal: true

class Recipient
  attr_reader :id

  class << self
    def find(urn, message)
      recipient = case urn
                    when /^urn:x-xikolo:account:user:(.+)/
                      Recipient::User.new(Regexp.last_match(1))
                    when /^urn:x-xikolo:account:group:(.+)/
                      Recipient::Group.new(Regexp.last_match(1), message)
                    else
                      raise ArgumentError.new("Invalid recipient: #{urn}")
                  end

      # Filter recipients by the specified consents of the message,
      # if the latter are present.
      if message.consents.any?
        recipient = FilterByConsents.new(recipient, message.consents)
      end

      recipient
    end
  end

  def initialize(id)
    @id = id
  end

  def account_service
    @account_service ||= Xikolo.api(:account).value!
  end

  class User < Recipient
    def each(&)
      Enumerator.new do |yielder|
        yielder << account_service.rel(:user).get({id:}).value!
      end.each(&)
    end

    ##
    # Check whether the user has consented to *all* required treatments by
    # looking up the user's groups and match corresponding treatment groups.
    def consented?(user, consents)
      groups = user.rel(:groups).get.value!.pluck('name')

      consents.all? {|consent| groups.include? consent }
    end
  end

  class Group < Recipient
    def initialize(id, message)
      super(id)
      @message = message
    end

    def each(&)
      Enumerator.new do |yielder|
        group = account_service.rel(:group).get({id:}).value!
        page = group.rel(:members).get.value!

        loop do
          rel = page.rel?(:next) ? page.rel(:next).get : false

          page.each {|user| yielder << user }
          break unless rel

          page = rel.value!
        end
      end.each(&)
    end

    ##
    # Check whether a given user of the recipients group has consented
    # to *all* required treatments. This is a performance optimization,
    # not issuing a request to xi-account per user (as it would the case
    # when reusing #consented? for a *single* user).
    def consented?(user, consents)
      consents_memberships(consents).all? do |_group, memberships|
        memberships.include? user.fetch('id')
      end
    rescue KeyError
      false
    end

    ##
    # Load all memberships for the given consents (treatment groups) in
    # parallel. Create a dictionary of treatment groups and their corresponding
    # members in the form of `{'treatment.abc': [uuid1, uuid2]}`.
    def consents_memberships(consents)
      @consents_memberships ||= consents.to_h do |group_name|
        Rails.cache.fetch(
          "announcements/#{@message.id}/groups/#{group_name}/memberships",
          expires_in: 5.minutes,
          race_condition_ttl: 5.seconds
        ) do
          user_ids = account_service.rel(:group).get({id: group_name}).then do |group|
            ids = Set.new
            Xikolo.paginate(
              group.rel(:memberships).get({per_page: 10_000})
            ) do |membership|
              ids.add membership['user']
            end
            ids
          end.value!

          [group_name, user_ids]
        end
      end
    end
  end
end
