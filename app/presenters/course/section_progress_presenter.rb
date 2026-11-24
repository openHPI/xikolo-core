# frozen_string_literal: true

class Course::SectionProgressPresenter < SectionPresenter
  def available?
    @section.available?
  end

  def optional?
    @section.optional?
  end

  def description
    @section.description
  end

  def items
    @section.items.published.user_state(@user.id).map do |item|
      ItemPresenter.for(item_attributes(item), course: @course, user: @user)
    end
  end

  private

  def item_attributes(item)
    {
      'id' => item.id,
      'title' => item.title,
      'content_type' => item.content_type_name,
      'exercise_type' => item.exercise_type,
      'user_state' => item.user_state,
      'optional' => item.optional?,
      'open_mode' => item.open_mode,
    }
  end
end
