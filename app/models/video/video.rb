# frozen_string_literal: true

module Video
  class Video < ::ApplicationRecord
    attribute :description, Xikolo::S3::Markup.new(uploads: {purpose: :video_description})

    has_one :visual, class_name: '::Course::Visual', dependent: :nullify
    has_one :item, class_name: '::Course::Item', as: :content, dependent: :restrict_with_exception
    has_many :subtitles, class_name: '::Video::Subtitle', dependent: :destroy
    has_many :thumbnails, class_name: '::Video::Thumbnail', dependent: :destroy
    belongs_to :pip_stream, class_name: '::Video::Stream', optional: true
    belongs_to :lecturer_stream, class_name: '::Video::Stream', optional: true
    belongs_to :slides_stream, class_name: '::Video::Stream', optional: true
    belongs_to :subtitled_stream, class_name: '::Video::Stream', optional: true

    validates :description, presence: true, allow_blank: true
    validates :title, presence: true, allow_blank: false
    validate :stream?

    default_scope { order updated_at: :desc }

    after_commit :delete_s3_objects!, on: :destroy

    class << self
      def referenced?(uri)
        # Check for remaining file references
        [
          where(transcript_uri: uri),
          where(reading_material_uri: uri),
          where(slides_uri: uri),
          where('description LIKE ?', "%#{uri}%"),
        ].reduce(:or).exists?
      end
    end

    def slides_url
      Xikolo::S3.object(slides_uri).public_url if slides_uri
    end

    def transcript_url
      Xikolo::S3.object(transcript_uri).public_url if transcript_uri
    end

    def reading_material_url
      Xikolo::S3.object(reading_material_uri).public_url if reading_material_uri
    end

    def audio_url
      uri = pip_stream&.audio_uri || lecturer_stream&.audio_uri
      Xikolo::S3.object(uri).public_url if uri
    end

    def thumbnail
      if pip_stream&.poster
        pip_stream.poster
      elsif lecturer_stream&.poster
        lecturer_stream.poster
      elsif slides_stream&.poster
        slides_stream.poster
      end
    end

    def duration
      return pip_stream.duration if pip_stream

      [lecturer_stream&.duration, slides_stream&.duration].compact.max
    end

    def as_api_v2
      @api_v2 ||= ::Video::Video::APIV2.new(self).as_json # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def pip_stream_collection
      return [] if pip_stream_id.blank?

      [[
        "#{pip_stream.title} (#{pip_stream.provider_name})",
        pip_stream_id,
      ]]
    end

    def lecturer_stream_collection
      return [] if lecturer_stream_id.blank?

      [[
        "#{lecturer_stream.title} (#{lecturer_stream.provider_name})",
        lecturer_stream_id,
      ]]
    end

    def slides_stream_collection
      return [] if slides_stream_id.blank?

      [[
        "#{slides_stream.title} (#{slides_stream.provider_name})",
        slides_stream_id,
      ]]
    end

    def subtitled_stream_collection
      return [] unless subtitled_stream_id
      return [] if subtitled_stream.blank?

      [[
        "#{subtitled_stream.title} (#{subtitled_stream.provider_name})",
        subtitled_stream_id,
      ]]
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Video instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Video')
    end

    def to_param
      id
    end

    # Per default, ActiveRecord maps a parent and a child in a polymorphic association based on the parents class
    # name, e.g. `Video::Video`, and stores it in a polymorphic type column, here `content_type`.
    # As we stored custom values in the `content_type` column before utilising polymorphic assocations, we need to
    # override the default polymorphic_name.
    def self.polymorphic_name
      'video'
    end

    private

    def stream?
      if lecturer_stream.blank? &&
         slides_stream.blank? &&
         pip_stream.blank?

        errors.add :lecturer_stream_id, :one_required
        errors.add :slides_stream_id, :one_required
        errors.add :pip_stream_id, :one_required
      end
    end

    def delete_s3_objects!
      files = [
        reading_material_uri,
        slides_uri,
        transcript_uri,
      ]
      files += description.file_refs if description
      files.compact.each do |file_uri|
        next if Video.referenced?(file_uri)

        S3FileDeletionJob.perform_now(file_uri)
      end
    end
  end
end
