# frozen_string_literal: true

module NewsService
class News < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :news

  # Read tracking was introduced on this date, older news count as read.
  MARK_AS_READ_BEFORE = Date.new(2016, 5, 24).freeze

  validates :author_id, presence: true
  validate :no_audience, if: :course_id

  has_many :emails,
    dependent: :delete_all

  has_many :translations,
    class_name: 'NewsTranslation',
    dependent: :delete_all,
    autosave: true

  has_many :read_states,
    dependent: :delete_all

  class << self
    def published
      where(publish_at: ...Time.zone.now)
    end

    def unread_by(user_id)
      where(publish_at: MARK_AS_READ_BEFORE..)
        .where.not(id: ReadState.where(user_id:).select(:news_id))
    end

    def with_read_states_for(user_id)
      joins(
        sanitize_sql_array(
          [
            'LEFT OUTER JOIN read_states ON read_states.news_id=news.id ' \
            "AND read_states.user_id = '%s'",
            user_id,
          ]
        )
      ).select('news.*', '(read_states.user_id is not null) AS read')
    end

    ##
    # Return only global (!) announcements visible to the user's groups
    #
    # When no user ID is given, only non-restricted announcements are returned.
    # Administrators (based on the existence of the news.announcement.show
    # permission) get to see all announcements regardless of restriction.
    #
    # Course announcements cannot be limited to user groups anyway (enforced by
    # validation), so we also enforce this in the query.
    #
    def for_groups(user:)
      return where(course_id: nil).where(audience: nil) unless user

      user = User.new(user)

      if user.allowed?('news.announcement.show')
        where(course_id: nil)
      else
        where(course_id: nil).where(audience: [nil, *user.groups])
      end
    end
  end

  class User
    def initialize(user_id)
      @user_id = user_id

      load_groups!
      load_permissions!
    end

    def groups
      @groups.value!
    rescue StandardError => e
      ::Sentry.capture_exception(e)
      []
    end

    def allowed?(permission)
      permissions.include? permission
    end

    private

    def load_groups!
      @groups = api.rel(:groups)
        .get({user: @user_id, per_page: 1000}).then do |groups|
          groups.pluck('name')
        end
    end

    def load_permissions!
      @permissions = api.rel(:user).get({id: @user_id}).then do |user|
        user.rel(:permissions).get
      end
    end

    def permissions
      @permissions.value!
    rescue StandardError => e
      ::Sentry.capture_exception(e)
      []
    end

    def api
      @api ||= Xikolo.api(:account).value!
    end
  end

  def available_languages
    translations.map(&:locale)
  end

  def translated_titles
    translated(&:title)
  end

  def mark_as_read(user_id)
    # rubocop:disable Rails/SkipsModelValidations
    ReadState.find_or_create_by!(
      news_id: id,
      user_id:
    ).touch
    # rubocop:enable Rails/SkipsModelValidations
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def translated
    translations.to_h do |translation|
      [translation.locale, yield(translation)]
    end
  end

  def no_audience
    errors.add(:audience, :must_be_nil) unless audience.nil?
  end
end
end
