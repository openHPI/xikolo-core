# frozen_string_literal: true

module Errors
  class Problem < StandardError
    attr_reader :reason

    def initialize(reason)
      super
      @reason = reason
    end

    def as_json(opts)
      {errors: {base: [reason]}}.as_json(opts)
    end
  end

  class InvalidItemType < Problem
    def initialize(reason = 'invalid_item_type')
      super
    end
  end

  class LoadResourcesError < Problem
    def initialize(reason = 'load_resources_error')
      super
    end
  end

  class InvalidTimeEffort < Problem
    def initialize(reason = 'invalid_time_effort')
      super
    end
  end

  class CourseItemUpdateError < Problem
    def initialize(reason = 'course_item_update_error')
      super
    end
  end

  class TimeEffortJobCancelled < Problem
    def initialize(reason = 'time_effort_job_cancelled')
      super
    end
  end

  class OverwriteTimeEffortError < Problem
    def initialize(reason = 'overwrite_time_effort_error')
      super
    end
  end

  class UnnecessaryUpdateError < Problem
    def initialize(reason = 'unnecessary_update_error')
      super
    end
  end
end
