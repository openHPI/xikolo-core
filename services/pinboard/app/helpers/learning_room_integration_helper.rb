# frozen_string_literal: true

module LearningRoomIntegrationHelper
  def belonging_resource_hash
    if params[:learning_room_id].present?
      {learning_room_id: params[:learning_room_id]}
    else
      params[:course_id].nil? ? {course_id: params[:question][:course_id]} : {course_id: params[:course_id]}
    end
  end
end
