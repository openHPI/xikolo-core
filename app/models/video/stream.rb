# frozen_string_literal: true

class Video::Stream < ApplicationRecord
  belongs_to :provider, class_name: '::Video::Provider'

  has_one_attached :video

  has_many :lecturer_videos,
    class_name: '::Video::Video',
    foreign_key: 'lecturer_stream_id',
    inverse_of: :lecturer_stream,
    dependent: :restrict_with_exception
  has_many :slides_videos,
    class_name: '::Video::Video',
    foreign_key: 'slides_stream_id',
    inverse_of: :slides_stream,
    dependent: :restrict_with_exception
  has_many :pip_videos,
    class_name: '::Video::Video',
    foreign_key: 'pip_stream_id',
    inverse_of: :pip_stream,
    dependent: :restrict_with_exception
  has_many :subtitled_videos,
    class_name: '::Video::Video',
    foreign_key: 'subtitled_stream_id',
    inverse_of: :subtitled_stream,
    dependent: :restrict_with_exception

  # Tracks how far the upload to the provider (e.g. Bunny) has progressed.
  # Only relevant for providers that receive uploads via a background job;
  # provider-synced providers (e.g. Vimeo) are always 'ready'.
  enum :upload_state, {
    waiting: 'waiting',
    uploading: 'uploading',
    ready: 'ready',
    failed: 'failed',
  }, default: 'ready'

  # A stream is persisted as soon as it is uploaded, before it has been
  # created on the provider (e.g. Bunny). It is only "backed by the provider"
  # once it has a provider video id; until then it may lack provider urls and
  # the id may legitimately be absent (and is not uniqueness-checked).
  validates :provider_video_id,
    uniqueness: {scope: :provider_id},
    allow_nil: true
  validates :title,
    presence: true,
    allow_blank: false
  validate :url?, if: -> { provider_video_id.present? }

  # The user-facing upload status for the admin UI. Provider-synced streams
  # (e.g. Vimeo) have no upload state and return :none. A failed upload is
  # shown as :invalid when no video could be created on the provider, and as
  # :failed when a video exists but the upload itself failed.
  def upload_status
    return :none unless tracks_upload?
    return :ready if ready?
    return :uploading if uploading?
    return :waiting if waiting?

    provider_video_id.blank? ? :invalid : :failed
  end

  # Only streams of providers that receive uploads via a background job
  # (e.g. Bunny) track upload progress. Provider-synced streams (e.g. Vimeo)
  # are always 'ready'.
  def tracks_upload?
    provider.provider_type == 'bunny'
  end

  # A poster URL that is playable in the browser. Bunny thumbnails live on the
  # authenticated CDN, so the stored URL is signed on demand; provider-synced
  # streams (e.g. Vimeo) use the stored URL as-is.
  def poster_url
    return if poster.blank?
    return poster unless tracks_upload? && provider_video_id.present?

    BunnySignedURL.new.call(provider_video_id).fetch(:thumbnail)
  end

  def start_upload!
    return unless tracks_upload?

    update!(upload_state: 'waiting', upload_error: nil)
  end

  def mark_uploading!
    update!(upload_state: 'uploading')
  end

  def mark_upload_ready!
    update!(upload_state: 'ready', upload_error: nil)
  end

  def mark_upload_failed!(error)
    update!(upload_state: 'failed', upload_error: error.to_s.truncate(500))
  end

  def retry_upload!
    unless tracks_upload? && failed?
      raise 'Only failed uploads can be retried'
    end

    update!(upload_state: 'waiting', upload_error: nil)
    UploadStreamToBunnyJob.perform_later(id)
  end

  default_scope { order(created_at: :desc) }

  after_commit(on: %i[create update]) do
    next unless Xikolo.config.video['audio_extraction']

    # Handle re-uploads of videos to the external video provider.
    # Update the audio if it has been previously created and is now outdated.
    if saved_change_to_sd_md5? && audio_uri?
      Video::ExtractAudioJob.perform_later(id)
    end
  end

  class << self
    def query(term)
      return all if term.blank?

      where('title ILIKE ?', "%#{sanitize_sql_like(term)}%")
        .reorder!('LOWER(title) ASC')
    end
  end

  def url?
    if sd_url.blank? && hd_url.blank? && hls_url.blank?
      errors.add :sd_url, :one_required
      errors.add :hd_url, :one_required
    end
  end

  def sync
    provider.sync_single provider_video_id
  end

  def downloads_expiring?
    return false unless provider.downloads_expire?

    # Expiration time is not yet stored
    return true if downloads_expire.blank?

    downloads_expire.in_time_zone.before?(5.minutes.from_now)
  end

  def refresh_downloads!
    download = provider.get_download_links(provider_video_id)

    update!(
      hd_download_url: download.links[:hd],
      sd_download_url: download.links[:sd],
      downloads_expire: download.expires
    )
  end

  def current_downloads
    if downloads_expiring?
      refresh_downloads!
    end

    {
      hd: hd_download_url,
      sd: sd_download_url,
    }
  end

  def provider_name
    provider.name
  end
end
