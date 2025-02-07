# frozen_string_literal: true

class Course::SectionProgressPresenter < SectionPresenter
  def available?
    @section.available
  end

  def optional?
    @section.optional
  end

  def description
    @section.description
  end

  def items
    # `@section.items` may be `nil` if the section is not available.
    # Make sure to always return an enumerable object and avoid a tri-state.
    return [] if @section.items.blank?

    @section.items.map do |i|
      item = Xikolo::Course::Item.new(i)
      ItemPresenter.for(item, course: @course, user: @user)
    end
  end
end
