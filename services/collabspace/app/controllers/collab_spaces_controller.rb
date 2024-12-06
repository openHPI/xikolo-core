# frozen_string_literal: true

require 'api_responder'

class CollabSpacesController < ApplicationController
  self.responder = ::APIResponder

  respond_to :json

  def index
    collab_spaces = CollabSpace.where collab_space_params

    if params.key? :with_membership
      user_id = params.require :user_id

      if ActiveModel::Type::Boolean.new.cast(params[:with_membership])
        collab_spaces = collab_spaces
          .joins(:memberships)
          .where(collab_space_memberships: {user_id:})
      else
        collab_spaces = collab_spaces.where.not(
          id: Membership.where(user_id:).select(:collab_space_id)
        )
      end
    end

    collab_spaces.reorder! sort_order if sort_order
    respond_with collab_spaces
  end

  def show
    respond_with CollabSpace.find(params[:id])
  end

  def create
    respond_with CollabSpace.create!(collab_space_params)
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  def update
    collab_space = CollabSpace.find(params[:id])
    collab_space.update!(collab_space_params)
    respond_with collab_space
  end

  def destroy
    respond_with CollabSpace.find(params[:id]).destroy
  end

  private

  def collab_space_params
    params.permit :name, :owner_id, :is_open,
      :kind, :course_id, :description, :details
  end

  def sort_order
    %w[name created_at].include?(params[:sort]) ? params[:sort] : nil
  end
end
