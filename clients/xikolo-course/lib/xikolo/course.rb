# frozen_string_literal: true

require 'acfs'

require 'xikolo/config'

module Xikolo
  module Course
    require 'xikolo/course/client'

    module Concerns
      require 'xikolo/course/concerns/channel'
      require 'xikolo/course/concerns/classifier'
      require 'xikolo/course/concerns/course'
      require 'xikolo/course/concerns/enrollment'
      require 'xikolo/course/concerns/section'
      require 'xikolo/course/concerns/item'
    end

    require 'xikolo/course/classifier'
    require 'xikolo/course/course'
    require 'xikolo/course/teacher'
    require 'xikolo/course/enrollment'
    require 'xikolo/course/section'
    require 'xikolo/course/section_choice'
    require 'xikolo/course/item'
    require 'xikolo/course/stat'
    require 'xikolo/course/statistic'
    require 'xikolo/course/visit'
    require 'xikolo/course/result'
    require 'xikolo/course/next_date'
    require 'xikolo/course/progress'
    require 'xikolo/course/persist_ranking_task'
  end
end
