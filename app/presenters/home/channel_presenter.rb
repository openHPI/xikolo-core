# frozen_string_literal: true

module Home
  class ChannelPresenter
    extend Forwardable
    include Rails.application.routes.url_helpers

    def_delegators :@channel,
      :code,
      :name

    def initialize(channel)
      @channel = channel
    end

    def logo_url
      @logo_url ||= Xikolo::S3.object(@channel.logo_uri).public_url if @channel.logo_uri?
    end

    def mobile_visual_url
      @mobile_visual_url ||= Xikolo::S3.object(@channel.mobile_visual_uri).public_url if @channel.mobile_visual_uri?
    end

    def stage_visual_url
      @stage_visual_url ||= Xikolo::S3.object(@channel.stage_visual_uri).public_url if @channel.stage_visual_uri?
    end

    def description
      Translations.new(@channel.description).to_s
    end

    def subtitle
      Translations.new(@channel.subtitle).to_s
    end

    def title
      Translations.new(@channel.title_translations).to_s
    end

    def meta_tags
      meta = {
        title: @channel.title,
        description: description&.truncate(150),
        og: {
          title: @channel.title,
          type: 'website',
          url: Xikolo.base_url.join(channel_path(@channel.code)),
          description: description&.truncate(150),
        },
      }

      meta[:og][:image] = stage_visual_url if stage_visual_url
      meta
    end

    def shorts
      signer = BunnySignedURL.new
      @shorts ||= @channel.shorts
        .active
        .with_video
        .merge(CourseService::Course.not_deleted)
        .map do |short|
          {
            id: short.id,
            thumbnail: signer.call(short.bunny_video_id)[:thumbnail],
          }
        end
    end

    def stage_item
      # Channel stage item must be first, if existing
      @stage_item ||= channel_stage_item
    end

    def info_link?
      info_link_url.present? && info_link_label.present?
    end

    def info_link_url
      @info_link_url ||= Translations.new(@channel.info_link&.dig('href')).to_s
    end

    def info_link_label
      @info_link_label ||= Translations.new(@channel.info_link&.dig('label')).to_s
    end

    def other_channels
      @other_channels ||= ::CourseService::Channel
        .where(public: true, affiliated: false, archived: false)
        .where.not(id: @channel.id)
        .order(Arel.sql('RANDOM()'))
        .limit(4)
    end

    private

    def channel_stage_item
      return if stage_visual_url.blank?

      StageItemPresenter.build(
        stage_visual_url,
        @channel.stage_statement
      )
    end
  end
end
