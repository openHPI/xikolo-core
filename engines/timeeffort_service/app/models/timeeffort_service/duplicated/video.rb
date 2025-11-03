# frozen_string_literal: true

module TimeeffortService
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Video < ApplicationRecord
    self.table_name = :videos

    belongs_to :pip_stream, class_name: 'TimeeffortService::Duplicated::Stream', optional: true
    belongs_to :lecturer_stream, class_name: 'TimeeffortService::Duplicated::Stream', optional: true
    belongs_to :slides_stream, class_name: 'TimeeffortService::Duplicated::Stream', optional: true

    def duration
      return pip_stream.duration if pip_stream

      [lecturer_stream&.duration, slides_stream&.duration].compact.max
    end
  end
end
end
