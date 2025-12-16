# frozen_string_literal: true

module CourseService
module CourseProviderSync # rubocop:disable Layout/IndentationWidth
  extend ActiveSupport::Concern

  included do
    after_commit :sync_providers, on: %i[create update]
  end

  def sync_providers
    CourseProvider.sync(id) if CourseProvider.sync?(self)
  end
end
end
