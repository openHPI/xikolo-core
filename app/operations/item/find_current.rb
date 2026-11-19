# frozen_string_literal: true

class Item::FindCurrent < ApplicationOperation
  def initialize(course:, user_id:, preview: false)
    super()

    @course = course
    @user_id = user_id
    @preview = preview
  end

  def call
    if user_enrolled?
      last_visit = CourseService::Visit.latest_for(user: @user_id, items: available_items.ids).take
      return last_visit.item if last_visit
    end

    available_items.limit(1).take
  end

  private

  def available_items
    @available_items ||= begin
      items =
        if @preview
          @course.items
        elsif user_enrolled?
          @course.items.all_available
        else
          # Anonymous users and not enrolled users only get to see open mode items
          @course.items.all_available.open_mode
        end

      items = items.course_order

      unless @course.legacy?
        items = CourseService::Structure::UserItemsSelector.new(@course.node, @user_id).items(scope: items)
      end

      items
    end
  end

  def user_enrolled?
    @user_enrolled ||= @course.enrollments.active.find_by(user_id: @user_id).present?
  end
end
