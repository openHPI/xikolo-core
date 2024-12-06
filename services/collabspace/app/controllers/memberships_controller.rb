# frozen_string_literal: true

require 'api_responder'

class MembershipsController < ApplicationController
  self.responder = ::APIResponder

  respond_to :json

  def create
    respond_with Membership.create membership_params
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  def index
    memberships = Membership.joins(:collab_space).where(membership_params)
    if params[:course_id]
      memberships.where!(collab_spaces: {course_id: params[:course_id]})
    end
    memberships.where!(collab_spaces: {kind: params[:kind]}) if params[:kind]

    respond_with memberships
  end

  def update
    membership = Membership.find(params[:id])
    membership.update(membership_params)
    respond_with membership
  end

  def destroy
    membership = Membership.find(params[:id])
    membership.destroy
    respond_with membership
  end

  private

  def membership_params
    if params[:learning_room_id].present?
      params[:collab_space_id] = params[:learning_room_id]
    end

    my_params = params.permit :collab_space_id, :user_id, :status
    fixup_string_or_array_value_for_status my_params
    my_params
  end

  # if we want to do where clauses with status: value AND status: [val1, val2]
  # we need string and array values for params, found no qay to tell strong
  # strong params that, so working around it
  def fixup_string_or_array_value_for_status(my_params)
    fix_status = my_params[:status].nil? && params[:status]
    my_params[:status] = params[:status].values if fix_status
  end
end
