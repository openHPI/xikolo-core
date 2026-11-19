# frozen_string_literal: true

class Cmi5ItemAnalyzeJob < ApplicationJob
  queue_as :default

  def perform(cmi5_item)
    cmi5_item.update!(Cmi5::Storyline::Analyzer.new(cmi5_item).to_h)
  end
end
