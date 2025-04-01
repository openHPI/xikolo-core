# frozen_string_literal: true

module Processors
  class RichTextProcessor < BaseProcessor
    attr_reader :rich_text

    def initialize(item)
      super

      @rich_text = nil
    end

    def load_resources!
      raise Errors::InvalidItemType unless item.content_type == 'rich_text'

      @rich_text = Xikolo.api(:course).value!
        .rel(:richtext)
        .get({id: item.content_id})
        .value!
    rescue Restify::NotFound
      raise Errors::LoadResourcesError
    end

    def calculate
      return if rich_text.blank?

      @time_effort = ItemTypes::RichText.new(rich_text['text']).time_effort
    end
  end
end
