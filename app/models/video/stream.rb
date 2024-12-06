# frozen_string_literal: true

class Video::Stream < ApplicationRecord
  belongs_to :provider, class_name: '::Video::Provider'

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

  validates :provider_video_id,
    presence: true,
    uniqueness: {scope: :provider_id}
  validates :title,
    presence: true,
    allow_blank: false
  validate :url?

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
    if sd_url.blank? && hd_url.blank?
      errors.add :sd_url, :one_required
      errors.add :hd_url, :one_required
    end
  end

  ## ROUTE HELPERS
  ## Ensure that Rails routing helpers can be used directly with Stream instances.

  def self.model_name
    ActiveModel::Name.new(self, nil, 'Stream')
  end

  def to_param
    id
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
