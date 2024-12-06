# frozen_string_literal: true

class Course::PositionPresenter < PrivatePresenter
  def_delegator :items, :each, :each_item
  attr_reader :section, :items

  def self.build(item, course, user)
    course.sections # load course sections
    presenter = new(course:, item:, user:)
    presenter.items!(user)
    presenter
  end

  def initialize(*args)
    super
    @items = []
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def course
    @course_presenter ||= CourseInfoPresenter.build @course, @user
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def items!(user)
    Xikolo::Course::Item.where section_id: @item.section_id, state_for: user.id, published: true do |items|
      @items = items.map do |item|
        ItemPresenter.for(item, course:, user:).tap do |presenter|
          presenter.active! if presenter.id == @item.id
        end
      end
    end
  end

  def prev_item
    @prev_item ||= find_prev_item
  end

  def next_item
    @next_item ||= find_next_item
  end

  protected

  def find_prev_item
    items.find {|e| e.id == @item.prev_item_id }
  end

  def find_next_item
    items.find {|e| e.id == @item.next_item_id }
  end
end
