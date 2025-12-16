# frozen_string_literal: true

module CourseService
module Vary # rubocop:disable Layout/IndentationWidth
  extend ActiveSupport::Concern

  included do
    before_action :_set_default_vary
  end

  def vary(*values)
    response.headers['Vary'] = [
      *response.headers.fetch('Vary', '').split(/[\s,]+/),
      *values.flatten.map(&:to_s),
    ].uniq.join(', ')
  end

  private

  def _set_default_vary
    vary %w[Accept Host]
  end
end
end
