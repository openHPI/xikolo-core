# frozen_string_literal: true

module CourseService
class DocumentsTagsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def index
    respond_with Document.all_tags
  end
end
end
