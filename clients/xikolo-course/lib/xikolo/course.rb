# frozen_string_literal: true

require 'acfs'

require 'xikolo/config'

module Xikolo
  module Course
    require 'xikolo/course/client'

    module Concerns
      require 'xikolo/course/concerns/section'
      require 'xikolo/course/concerns/item'
    end
  end
end
