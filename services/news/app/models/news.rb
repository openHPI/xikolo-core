# frozen_string_literal: true

class News < ApplicationRecord
  self.table_name = :news

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
      ::Mnemosyne.attach_error(e)
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
      ::Mnemosyne.attach_error(e)
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

  def visual_url
    Xikolo::S3.object(visual_uri).public_url if visual_uri?
  end

  def upload_via_id(upload_param)
    # Validate upload
    upload = Xikolo::S3::SingleFileUpload.new upload_param,
      purpose: 'news_visual'
    return if upload.empty?

    upload_object = upload.accepted_file!
    old_visual = visual_uri
    original_filename = File.basename upload_object.key
    extname = File.extname original_filename
    bucket = Xikolo::S3.bucket_for(:news)
    nid = UUID4(id).to_str(format: :base62)
    revision = revision(old_visual)
    object = bucket.object("news/#{nid}/visual_v#{revision}#{extname}")

    # Save upload to xi-news bucket
    object.copy_from(
      upload_object,
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      content_type: upload_object.content_type,
      cache_control: 'public, max-age=7776000',
      content_disposition: "inline; filename=\"#{original_filename}\""
    )
    self.visual_uri = object.storage_uri
    Xikolo::S3.object(old_visual).delete if old_visual
  rescue Aws::S3::Errors::ServiceError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    errors.add :visual_upload_id, 'could not process file upload'
  rescue RuntimeError
    errors.add :visual_upload_id, 'invalid upload'
  end

  # TODO: As soon as backward compatibility is no longer needed,
  # TODO: this method can be rename to handle_visual or upload_visual
  def upload_via_uri(upload_param)
    # Validate upload
    upload = Xikolo::S3::UploadByUri.new \
      uri: upload_param,
      purpose: 'news_visual'
    unless upload.valid?
      errors.add :visual_uri, 'Upload not valid - ' \
                              'either file upload was rejected or access to it is forbidden.'
      return
    end

    # Save upload to xi-news bucket
    nid = UUID4(id).to_str(format: :base62)
    old_visual = visual_uri
    revision = revision(old_visual)
    result = upload.save \
      bucket: :news,
      key: "news/#{nid}/visual_v#{revision}#{upload.extname}",
      metadata_directive: 'REPLACE',
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_type: upload.content_type,
      content_disposition: "inline; filename=\"#{upload.sanitized_name}\""
    if result.is_a?(Symbol)
      errors.add :visual_uri, 'Could not save file - ' \
                              'access to destination is forbidden.'
      return
    end
    self.visual_uri = result.storage_uri
    Xikolo::S3.object(old_visual).delete if old_visual
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

  def revision(visual_uri)
    # mixed named captures and numbered captures
    /.*_[rv](?<revision>[0-9]+)(?:\.[a-z]{2,4})?/ =~ visual_uri
    revision ||= 0
    revision.to_i + 1
  end

  def translated
    translations.to_h do |translation|
      [translation.locale, yield(translation)]
    end
  end

  def no_audience
    errors.add(:audience, :must_be_nil) unless audience.nil?
  end
end
