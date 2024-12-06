# frozen_string_literal: true

module Proctoring
  class ItemContext < CourseContext
    # @param course [Xikolo::Course::Course]
    # @param item [Xikolo::Course::Item]
    # @param enrollment [Xikolo::Course::Enrollment|Course::Enrollment]
    def initialize(course, item, enrollment)
      super(course, enrollment)

      @item = item
    end

    def enabled?
      @enabled ||= super && item_proctored?
    end

    def can_enable?
      @can_enable ||= super && item_proctored?
    end

    private

    def item_proctored?
      !@item.nil? && @item.proctored
    end
  end
end
