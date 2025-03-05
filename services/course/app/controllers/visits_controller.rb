# frozen_string_literal: true

class VisitsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder
  respond_to :json

  # lets keep only one visit per item and user in the db,
  # but have the last visit's timestamp in updated_at
  def create
    # rubocop:disable Rails/SkipsModelValidations
    Visit.upsert(
      {user_id: params[:user_id], item_id: params[:item_id]},
      unique_by: %i[user_id item_id],
      on_duplicate: Arel.sql(<<~SQL.squish)
        updated_at = CURRENT_TIMESTAMP
      SQL
    )
    # rubocop:enable Rails/SkipsModelValidations

    respond_with({}, {location: ''})
  end

  def show
    respond_with Visit.find_by!(
      user_id: params[:user_id],
      item_id: params[:item_id]
    )
  end
end
