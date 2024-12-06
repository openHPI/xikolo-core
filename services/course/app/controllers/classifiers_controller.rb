# frozen_string_literal: true

class ClassifiersController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    classifiers = Classifier.all

    if params['cluster'].present?
      classifiers.where! cluster_id: params['cluster'].split(',')
    end

    unless params['q'].nil?
      classifiers.where! 'title LIKE ?', "%#{params['q']}%"
    end

    respond_with classifiers.offset(params['offset'].to_i)
  end

  def show
    respond_with Classifier.find params[:id]
  end

  def max_per_page
    500
  end
end
