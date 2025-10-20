# frozen_string_literal: true

module Navigation
  class TabsPreview < ViewComponent::Preview
    # Use the `with_tab` slot to provide tab elements.
    def default
      render Navigation::Tabs.new do |c|
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">Another link</a>'.html_safe }
      end
    end

    # Use the `active` parameter to indicate the currently active item.
    # @label Active state
    def active
      render Navigation::Tabs.new do |c|
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab(active: true) { '<a href=# class="bs-a">An active link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">Another link</a>'.html_safe }
      end
    end

    # Use the `collapsible: true` config to enable the behavior.
    def collapsible
      render Navigation::Tabs.new(collapsible: true) do |c|
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">Another link</a>'.html_safe }
      end
    end

    # Use the slot `with_additional_content` to provide additional items.
    def additional_content
      render Navigation::Tabs.new(collapsible: true) do |c|
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_tab { '<a href=# class="bs-a">A link</a>'.html_safe }
        c.with_additional_item { '<button class="btn btn-default" type="button">Button 1 </button>'.html_safe }
        c.with_additional_item { '<button class="btn btn-default" type="button">Button 2</button>'.html_safe }
        c.with_additional_item { '<button class="btn btn-default" type="button">Button 3</button>'.html_safe }
      end
    end

    # The string provided as `controls` of `with_tab` must match the `id` param of `with_panel`.
    def tabpanels
      render_with_template
    end
  end
end
