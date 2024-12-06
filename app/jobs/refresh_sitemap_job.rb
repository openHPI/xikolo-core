# frozen_string_literal: true

require 'rake'
Xikolo::Web::Application.load_tasks

class RefreshSitemapJob < ApplicationJob
  queue_as :default
  queue_with_priority :reporting

  def perform
    Rake::Task['sitemap:refresh'].invoke
  end
end
