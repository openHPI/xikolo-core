# frozen_string_literal: true

module Admin
  module VideosHelper
    # Maps a stream's upload status to a daisyUI badge color.
    def upload_status_class(status)
      case status
        when :ready then 'x-badge-success'
        when :uploading then 'x-badge-info'
        when :waiting then 'x-badge-warning'
        when :failed, :invalid then 'x-badge-error'
        else ''
      end
    end

    def upload_status_label(status)
      return nil if status == :none

      t("admin.videos.index.upload_status.#{status}")
    end

    # Renders the upload status badge for a stream (or nothing when the stream
    # does not track uploads, e.g. provider-synced Vimeo streams).
    def upload_status_badge(stream)
      status = stream.upload_status
      return ''.html_safe if status == :none

      title = stream.upload_error.presence
      tag.div(
        upload_status_label(status),
        class: "x-badge #{upload_status_class(status)}",
        title: title
      )
    end

    def copy_id_button(stream)
      tag.button(
        t(:'admin.videos.index.copy_id'),
        data: {behavior: 'copy-to-clipboard', text: stream.id}
      )
    end
  end
end
