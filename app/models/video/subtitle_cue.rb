# frozen_string_literal: true

require 'webvtt'

module Video
  class SubtitleCue < ::ApplicationRecord
    belongs_to :subtitle, class_name: '::Video::Subtitle'

    # Use new interval type (default in Rails 7):
    attribute :start, :interval
    attribute :stop, :interval

    validates :identifier, presence: true, uniqueness: {scope: :subtitle_id}
    validates :start, :stop, presence: true
    validate :start_before_stop

    default_scope { order(identifier: :asc) }

    serialize :style, Hash

    def as_api_v2
      @api_v2 ||= ::Video::SubtitleCue::APIV2.new(self).as_json # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def to_vtt
      "#{identifier}\n#{formatted_start} --> #{formatted_stop} #{settings}\n#{vtt_text}\n"
    end

    def settings
      style.map {|k, v| "#{k}:#{v}" }.join(' ')
    end

    def formatted_start
      WebVTT::Timestamp.new(start).to_s
    end

    def formatted_stop
      WebVTT::Timestamp.new(stop).to_s
    end

    def vtt_text
      text.gsub(
        /[&<>]/,
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;'
      )
    end

    private

    def start_before_stop
      return if start.blank? || stop.blank?

      if stop <= start
        errors.add(:stop, :invalid)
      end
    end
  end
end
