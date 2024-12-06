# frozen_string_literal: true

class VisitsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder
  respond_to :json

  # lets keep only one visit per item and user in the db,
  # but have the last visit's timestamp in updated_at
  def create
    visit = Visit.find_or_initialize_by(
      user_id: params[:user_id],
      item_id: params[:item_id]
    )
    if visit.new_record?
      visit.save!
    else
      # also save if nothing has changed so updated_at is up to date
      # rubocop:disable Rails/SkipsModelValidations
      visit.touch
      # rubocop:enable Rails/SkipsModelValidations
    end
    respond_with({}, {location: ''})
  rescue ActiveRecord::RecordNotUnique
    # another request was executed in parallel and succeeded create the visit
    # we were slower and got a unique index violation
    # lets simply retry (fetch visit and touch it):
    retry
  end

  def show
    respond_with Visit.find_by!(
      user_id: params[:user_id],
      item_id: params[:item_id]
    )
  end
end
