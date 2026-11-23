# frozen_string_literal: true

module CourseService
class Channel < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :channels

  include FileReference

  has_many :channels_courses,
    class_name: 'CourseService::ChannelsCourse',
    dependent: :destroy

  has_many :courses, through: :channels_courses
  has_many :shorts, through: :courses

  validates :code, presence: true, uniqueness: true
  validate :validate_title_translations_structure
  validate :validate_subtitle
  validates :position, allow_nil: true, numericality: {only_integer: true}

  after_commit :destroy_referenced_files!, on: :destroy

  file_reference :logo, lambda {|channel, rev, upload|
    cid = UUID4(channel.id).to_str(format: :base62)
    {
      key: "channels/#{cid}/logo_v#{rev}#{upload.extname}",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_disposition: 'inline',
      content_type: upload.content_type,
    }
  }

  file_reference :stage_visual, lambda {|channel, rev, upload|
    cid = UUID4(channel.id).to_str(format: :base62)
    {
      key: "channels/#{cid}/stage_visual_v#{rev}#{upload.extname}",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_disposition: 'inline',
      content_type: upload.content_type,
    }
  }

  file_reference :mobile_visual, lambda {|channel, rev, upload|
    cid = UUID4(channel.id).to_str(format: :base62)
    {
      key: "channels/#{cid}/mobile_visual_v#{rev}#{upload.extname}",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_disposition: 'inline',
      content_type: upload.content_type,
    }
  }

  class << self
    def ordered
      order(:position, :code)
    end

    def not_deleted
      where(archived: false)
    end

    def by_identifier(param)
      where(code: param).or where(id: UUID4.try_convert(param))
    end

    def public
      where(archived: false, public: true)
    end
  end

  def destroy_referenced_files!
    Xikolo::S3.object(logo_uri).delete if logo_uri?

    if stage_visual_uri?
      Xikolo::S3.object(stage_visual_uri).delete
    end

    if mobile_visual_uri?
      Xikolo::S3.object(mobile_visual_uri).delete
    end
  rescue Aws::S3::Errors::ServiceError => e
    Sentry.capture_exception(e)
  end

  def title
    Translations.new(title_translations).to_s
  end

  def validate_title_translations_structure
    if title_translations.blank?
      errors.add(:title_translations, 'must be present')
      return
    end

    I18n.available_locales.each do |locale|
      value = title_translations[locale.to_s]
      errors.add(:title_translations, "#{locale} must be present") if value.blank?
    end
  end

  def validate_subtitle
    return if subtitle.nil?
    return if subtitle.is_a?(Hash) && subtitle.values.all? {|value| value.is_a?(String) && !value.match?(/[\r\n]/) }

    errors.add(:subtitle, :invalid)
  end

  ##
  # Stage courses shown on the channels page.
  # Excludes deleted, hidden, and group-restricted courses. It ignores
  # courses in preparation. Consequently, only publicly available courses
  # for all users are shown.
  #
  def stage_courses
    courses
      .not_deleted
      .where.not(placement: [])
      .where(groups: [])
      .where(status: %w[active archive])
  end

  def logo_url
    Xikolo::S3.object(logo_uri).public_url if logo_uri?
  end
end
end
