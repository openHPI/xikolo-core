# frozen_string_literal: true

module CacheHelpers
  def with_caching
    old_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    Rails.cache.clear
    yield
  ensure
    Rails.cache.clear
    Rails.cache = old_cache_store
  end
end

RSpec.configure do |config|
  config.include CacheHelpers
end
