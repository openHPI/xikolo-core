# frozen_string_literal: true

class ConflictsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    par = index_params.merge! filter_params

    if params[:user_filter].present?
      user_ids = []
      Xikolo.paginate(
        Xikolo.api(:account).value!.rel(:users).get(query: params[:user_filter])
      ) do |user|
        user_ids << user['id']
      end

      records = Conflict.where(par).where(
        Conflict.arel_table[:reporter].in(user_ids).or(
          Conflict.arel_table[:accused].in(user_ids)
        )
      )

      respond_with records
    else
      respond_with Conflict.where par
    end
  end

  def show
    respond_with Conflict.find_by! show_params
  end

  def create
    conflict = Conflict.create! create_params
    respond_with conflict
  end

  def update
    respond_with Conflict.find(params[:id]).update! update_params
  end

  def destroy
    respond_with Conflict.find(params[:id]).destroy!
  end

  private

  def filter_params
    merge_params = params.permit(:reason, :open, :conflict_subject_type)

    if merge_params.key?(:conflict_subject_type)
      case merge_params[:conflict_subject_type]
        when ''
          merge_params.delete :conflict_subject_type
        when 'blank'
          merge_params[:conflict_subject_type] = ''
      end
    end

    if merge_params.key?(:open) && params[:open].blank?
      merge_params.delete(:open)
    end

    if merge_params.key?(:reason) && params[:reason].blank?
      merge_params.delete(:reason)
    end

    merge_params
  end

  def index_params
    params.permit %i[
      id
      conflict_subject_id
      comment
      reporter
      peer_assessment_id
      accused
    ]
  end

  def show_params
    params.permit %i[
      id
      reason
      open
      conflict_subject_id
      conflict_subject_type
      comment
      reporter
      peer_assessment_id
      accused
    ]
  end

  def update_params
    params.permit :open
  end

  def create_params
    params.permit %i[id
                     reason
                     conflict_subject_id
                     conflict_subject_type
                     comment
                     reporter
                     peer_assessment_id
                     accused]
  end
end
