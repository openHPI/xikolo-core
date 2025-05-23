# frozen_string_literal: true

# Helps with the integration of pinboards that is meant for courses
# into other resources . This module defines new methods for getting routes that
# have no special indication of whether they are for a course or a collabspace
# when these methods are called they figure out in which context they were
# called e.g. if there is a learning_room_id in params then it's the
# collabspace context otherwise the course context.
# Then they call the correct route helper to return the right route for the
# current context.
#
# Example:
# You call **question_index_path**, depending on the URL/params/context this
# is routed to:
# - course_question_index_path
# or
# - course_learning_room_question_index_path
#
# these routes still have to be defined in routes.rb.
# This is just kind of a proxy method call.
#
module PinboardRoutesHelper
  def self.included(base_controller)
    # for some reason some other module seems to want to include this
    return unless base_controller.respond_to? :helper_method

    base_controller.helper_method(*public_instance_methods(false))
  end

  # there is a method in CollabspacesControllerCommon (which all full fledged)
  # collabspace controllers include, that defines this as simply true
  # duck typing FTW
  def in_learning_room_context?
    params[:learning_room_id].present?
  end

  def in_section_context?
    params[:section_id].present?
  end

  ROUTE_HELPER_ENDINGS = %i[_url _path _rfc6570 _url_rfc6570 _path_rfc6570].freeze

  # this handles normal resources like question_index_path
  def self.define_dynamic_resource_routes
    %i[
      pinboard_index
      question
      question_index
      answer
      answer_index
      question_pinboard_comment
      question_pinboard_comment_index
      answer_pinboard_comment
      answer_pinboard_comment_index
    ].each do |route_name|
      ROUTE_HELPER_ENDINGS.each do |ending|
        full_route = route_name.to_s + ending.to_s
        define_method full_route do |*args|
          send contextual_resource_route_from(full_route), *args
        end
      end
    end
  end

  # this handles specifically designated action routes e.g. member do post :comment end
  # so comment_question_path then gets to be comment_course_question_path (or a learning_room inbetween)
  def self.define_dynamic_action_routes
    [
      %i[comment_ question],
      %i[upvote_ question],
      %i[accept_answer_ question],
      %i[edit_ question],
      %i[abuse_report_ question],
      %i[block_ question],
      %i[unblock_ question],
      %i[comment_ answer],
      %i[upvote_ answer],
      %i[downvote_ answer],
      %i[edit_ answer],
      %i[abuse_report_ answer],
      %i[block_ answer],
      %i[unblock_ answer],
      %i[edit_ answer_pinboard_comment],
      %i[abuse_report_ answer_pinboard_comment],
      %i[block_ answer_pinboard_comment],
      %i[unblock_ answer_pinboard_comment],
      %i[edit_ question_pinboard_comment],
      %i[abuse_report_ question_pinboard_comment],
      %i[block_ question_pinboard_comment],
      %i[unblock_ question_pinboard_comment],
    ].each do |action, resource|
      ROUTE_HELPER_ENDINGS.each do |ending|
        resource_route = resource.to_s + ending.to_s
        full_action_route = action.to_s + resource_route
        define_method full_action_route do |*args|
          my_route = action.to_s + contextual_resource_route_from(resource_route)
          send my_route, *args
        end
      end
    end
  end

  def self.define_dynamic_routes
    define_dynamic_action_routes
    define_dynamic_resource_routes
  end

  def comment_path(comment, commentable)
    if commentable.is_a? Xikolo::Pinboard::Question
      question_pinboard_comment_path id: comment.id, question_id: comment.commentable_id
    else
      answer_pinboard_comment_path id: comment.id, answer_id: comment.commentable_id
    end
  end

  def edit_comment_path(comment, commentable)
    if commentable.is_a? Xikolo::Pinboard::Question
      edit_question_pinboard_comment_path id: comment.id, question_id: comment.commentable_id
    else
      edit_answer_pinboard_comment_path id: comment.id, answer_id: comment.commentable_id
    end
  end

  def abuse_report_comment_path(comment, commentable)
    if commentable.is_a? Xikolo::Pinboard::Question
      abuse_report_question_pinboard_comment_path id: comment.id, question_id: comment.commentable_id
    else
      abuse_report_answer_pinboard_comment_path id: comment.id, answer_id: comment.commentable_id
    end
  end

  def block_comment_path(comment, commentable)
    if commentable.is_a? Xikolo::Pinboard::Question
      block_question_pinboard_comment_path id: comment.id, question_id: comment.commentable_id
    else
      block_answer_pinboard_comment_path id: comment.id, answer_id: comment.commentable_id
    end
  end

  def unblock_comment_path(comment, commentable)
    if commentable.is_a? Xikolo::Pinboard::Question
      unblock_question_pinboard_comment_path id: comment.id, question_id: comment.commentable_id
    else
      unblock_answer_pinboard_comment_path id: comment.id, answer_id: comment.commentable_id
    end
  end

  define_dynamic_routes

  private

  def contextual_resource_route_from(artificial_route)
    my_route = artificial_route.dup # mutability bites!
    my_route = "learning_room_#{my_route}" if in_learning_room_context?
    my_route = "section_#{my_route}" if in_section_context?
    "course_#{my_route}"
  end
end
# rubocop:enable all
