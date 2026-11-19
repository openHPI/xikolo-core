# frozen_string_literal: true

module Items
  class DownloadAssetCardPreview < ViewComponent::Preview
    # @group Download Asset Cards
    def default
      render DownloadAssetCard.new(
        title: 'Präsentationsfolien Titel Headline',
        url: '#',
        file_type: 'pdf',
        size: 3_124_000
      )
    end

    def with_long_title
      render DownloadAssetCard.new(
        title: 'Headline That Is Long And Will Truncate At Two Lines',
        url: '#',
        file_type: 'pdf',
        size: 3_124_000
      )
    end

    def without_metadata
      render DownloadAssetCard.new(
        title: 'Additional Course Material',
        url: '#'
      )
    end
    # @endgroup
  end
end
