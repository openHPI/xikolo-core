# frozen_string_literal: true

class Channel < ApplicationRecord
  include FileReference

  has_many :courses, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :position, allow_nil: true, numericality: {only_integer: true}

  default_scope { not_deleted.ordered }

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
      where(arel_table[:code].eq(param).or(arel_table[:id].eq(UUID4.try_convert(param))))
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
    Mnemosyne.attach_error(e)
  end
end
