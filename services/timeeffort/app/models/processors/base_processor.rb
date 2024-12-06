# frozen_string_literal: true

module Processors
  class BaseProcessor
    require 'errors'

    attr_reader :item, :time_effort

    def initialize(item)
      @item = item
      @time_effort = nil
    end

    def load_resources!; end

    def calculate; end

    def patch_items!
      raise Errors::InvalidTimeEffort if time_effort.blank?

      # Theoretically, only one job is running and can perform updates.
      # Lock item to ensure that no conflicting updates occur.
      item.with_lock do
        raise Errors::UnnecessaryUpdateError unless item.set_calculated_time_effort(time_effort).success?
        raise Errors::UnnecessaryUpdateError if item.time_effort_overwritten

        Xikolo.api(:course).value!
          .rel(:item)
          .patch({time_effort: item.reload.time_effort}, {id: item.id})
          .value!
      end
    rescue Restify::ClientError => e
      # The job should be cancelled if item is deleted, but action is asynchronous.
      # Fail silently if item was deleted in the meantime.
      return if e.code == 404

      # Raise error otherwise
      raise Errors::CourseItemUpdateError
    rescue Errors::UnnecessaryUpdateError
      # noop
    end
  end
end
