# frozen_string_literal: true

class DocumentsTagsController < ApplicationController
  respond_to :json

  def index
    respond_with Document.all_tags
  end
end
