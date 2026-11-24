# frozen_string_literal: true

module Course
  class RequiredItemPresenter
    # Gathers the required items for an item in the context of a user
    #
    # @param item [CourseService::Item] the item with requirements
    # @param user [Account::User] the user to determine requirements fulfillment for
    # @return [Array<CourseService::Item>] a list of required items, or nil if all requirements are fulfilled
    def self.requirements_for(item, user)
      return if item['required_item_ids'].blank?

      required_items = ::CourseService::Item.where(id: item['required_item_ids']).map do |req_item|
        new(req_item, user)
      end

      return if required_items.reject(&:fulfilled?).blank?

      required_items
    end

    def initialize(item, user)
      @item = item
      @user = user
    end

    def fulfilled?
      @fulfilled ||= @item.fulfilled_for?(@user)
    end

    def icon
      fulfilled? ? 'circle-check' : 'circle-xmark'
    end

    def icon_color_scheme
      fulfilled? ? 'success' : 'error'
    end

    def hint
      return if fulfilled?

      return I18n.t(:'items.requirements.visit_requirement') if %w[CourseService::Richtext
                                                                   Video::Video].include? @item['content_type']

      I18n.t(
        :'items.requirements.result_requirement',
        threshold: Xikolo.config.required_assessment_threshold
      )
    end

    def id
      @item['id']
    end

    def title
      @item['title']
    end

    def course_code
      @course_code ||= @item.section.course.course_code
    end
  end
end
