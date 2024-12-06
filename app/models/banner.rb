# frozen_string_literal: true

class Banner < ApplicationRecord
  validates :file_uri, :alt_text, presence: true
  validates :link_target,
    presence: {if: -> { link_url.present? }},
    inclusion: {in: %w[self blank], allow_nil: true, message: 'invalid'}
  validates :link_url, presence: {if: -> { link_target.present? }}

  after_commit :delete_s3_object!, on: :destroy

  class << self
    def published
      where(publish_at: ..Time.zone.now)
    end

    def not_expired
      where('expire_at IS NULL OR expire_at >= ?', Time.zone.now)
    end

    def active
      published.not_expired
    end

    def current
      active.order(publish_at: :asc).take
    end

    def upload!(file)
      return unless file.present? && File.file?(file)

      bucket = Xikolo::S3.bucket_for(:banners)

      filename = File.basename(file)
      bucket.put_object(
        key: File.join('banners', filename),
        body: file,
        acl: 'public-read'
      )
    end
  end

  def image_url
    Xikolo::S3.object(file_uri).public_url if file_uri
  end

  def delete_s3_object!
    # Banners are cached for the specified cache duration, so it is (fairly)
    # safe to remove the corresponding S3 file after twice the time.
    S3FileDeletionJob.set(
      wait: 2 * Global::CourseListBanner::CACHE_DURATION
    ).perform_later(file_uri)
  end
end
