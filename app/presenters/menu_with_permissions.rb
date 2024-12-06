# frozen_string_literal: true

class MenuWithPermissions
  class << self
    def item(text, icon, opts = {}, &block)
      items << {text:, icon:}.merge(opts).tap do |item|
        next unless block

        submenu = Class.new(self)
        submenu.instance_exec(&block)
        item[:submenu] = submenu
      end
    end

    def items
      @items ||= []
    end

    def items_for(user, course = nil)
      items.map do |item|
        Item.new(course, item, item[:submenu]&.items_for(user, course))
      end.select do |item|
        item.accessible? user
      end
    end
  end

  class Item
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper

    def initialize(course, opts = {}, submenu = nil)
      @course = course
      @opts = opts
      @submenu = submenu
    end

    def text
      I18n.t @opts.fetch(:text)
    end

    def id
      # Generates unique id
      "item-#{object_id}"
    end

    def icon_class
      @opts.fetch :icon
    end

    def link
      return '#' unless @opts[:route]

      if @opts[:route].respond_to? :call
        # For callables, execute them in the context of this class, so that e.g. the route helpers are available
        instance_exec @course, &@opts[:route]
      else
        send :"#{@opts[:route]}_path", @course
      end
    end

    def popover
      # Adds a popover for the open mode to the "Learnings" tab item.
      'popover-openmode' if @opts[:route] == :course_resume
    end

    def active?(request)
      active_self?(request) || active_sub_item?(request)
    end

    def accessible?(user)
      return true unless @opts[:if]

      @opts[:if].call user, @course
    end

    def submenu?
      @submenu&.any?
    end

    attr_reader :submenu

    private

    def active_self?(request)
      if @opts[:active]
        @opts[:active].call(request)
      else
        request.fullpath == link
      end
    end

    def active_sub_item?(request)
      @submenu&.any? {|child| child.active?(request) }
    end
  end
end
