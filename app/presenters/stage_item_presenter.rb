# frozen_string_literal: true

class StageItemPresenter < PrivatePresenter
  include MarkdownHelper
  include Rails.application.routes.url_helpers

  attr_reader :quote_by, :course_path, :visual_url

  def self.build(visual, statement, course_path: nil)
    new(visual_url: visual, statement:, course_path:).tap do |presenter|
      presenter.parse_statement! unless statement.nil?
    end
  end

  def parse_statement!
    @quote_by = @statement[/(.*)###(.*)/m, 2]
    unless @quote_by.nil?
      @quote_by.strip!
      @statement = @statement.split('###')[0]
    end
    @statement&.strip!
  end

  def render_statement
    render_markdown @statement
  end

  def statement?
    @statement.present?
  end
end
