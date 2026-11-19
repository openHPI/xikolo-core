# frozen_string_literal: true

class Cmi5ContentsController < ApplicationController
  skip_forgery_protection only: :show

  def show
    # The package blob ID is part of the lookup to ensure cached
    # responses are invalidated when the package changes.
    cmi5_item = Cmi5::Item.joins(:package_attachment).find_by!(
      id: params[:id],
      package_attachment: {blob_id: params[:blob_id]}
    )

    blob = cmi5_item.files.with_attached_file.find_by!(file_path: params[:path]).file.blob

    http_cache_forever(public: true) do
      send_data blob.download,
        type: blob.content_type,
        disposition: 'inline'
    end
  end
end
