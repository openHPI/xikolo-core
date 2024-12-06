# frozen_string_literal: true

module Navigation
  class Bar < ApplicationComponent
    VALID_COMPONENTS = %w[
      about
      administration
      announcements
      channels
      courses
      courses_megamenu
      home
      language_chooser
      login
      profile
      register
    ].freeze

    MOBILE_SECONDARY_COMPONENTS = %w[
      profile
      login
    ].freeze

    COMPONENT_OVERRIDES = {'courses_megamenu' => 'courses'}.freeze

    def initialize(user:, allowed: nil)
      super

      @user = user

      # By default, all components will be shown if configured. A subset
      # can be passed in using the allowed: keyword argument.
      @allowed_components = allowed || VALID_COMPONENTS
    end

    private

    def render?
      Xikolo.config.header['visible']
    end

    def merge_to_right?
      Xikolo.config.header['merge_components']
    end

    def left_navigation
      components_for 'primary' unless merge_to_right?
    end

    def right_navigation
      components_for 'primary' if merge_to_right?
    end

    def responsive_items(type)
      (Xikolo.config.header['primary'] || []).filter_map do |component|
        nav_item = build_component(COMPONENT_OVERRIDES.fetch(component, component))

        if (type == 'hide-first' && nav_item&.type == 'hide-first') ||
           (type == 'hide-last' && nav_item&.type)
          nav_item
        end
      end
    end

    def responsive_dropdowns
      %w[hide-last hide-first].map do |breakpoint|
        responsive_dropdown(breakpoint)
      end
    end

    def responsive_dropdown(type)
      items = responsive_items(type)

      return [] unless items.any?

      if items.length > 1
        Navigation::Item.new(
          text: type == 'hide-last' ? t(:'header.navigation.menu') : t(:'header.navigation.more'),
          type: "menu-#{type}"
        ).tap do |dropdown|
          items.each do |item|
            dropdown.with_item(item)
          end
        end
      else
        # If there is only one item in the dropdown,
        # display it as a top navigation item
        items.first.type = "menu-#{type}"
        items.first
      end
    end

    def platform_navigation
      components_for 'secondary'
    end

    def mobile_left_navigation
      # All configured components (primary + secondary) except for
      # the ones moved to the right mobile navigation
      items = %w[primary secondary].flat_map do |item|
        Xikolo.config.header[item] || []
      end - MOBILE_SECONDARY_COMPONENTS

      items.filter_map do |component|
        build_component(
          COMPONENT_OVERRIDES.fetch(component, component)
        )
      end
    end

    def mobile_right_navigation
      # If configured, a subset of components defined at MOBILE_SECONDARY_COMPONENTS
      # will be part of the right-side navigation on mobile view
      MOBILE_SECONDARY_COMPONENTS.filter_map do |item|
        build_component(item) if
        (Xikolo.config.header['primary'] || []).include?(item) ||
        (Xikolo.config.header['secondary'] || []).include?(item)
      end
    end

    def build_component(name)
      factory.resolve(name)
    end

    def components_for(type)
      (Xikolo.config.header[type] || []).filter_map do |component|
        build_component(component)
      end
    end

    def render_logo?
      Xikolo.config.header['logo'].present?
    end

    def brand_logo
      config = Xikolo.config.header['logo']

      Navigation::Logo.new(basename: config['basename'], href: config['href'], alt: config['alt'])
    end

    def factory
      @factory ||= ComponentFactory.new(view_context, @user, @allowed_components)
    end
  end

  class ComponentFactory
    def initialize(context, user, allowed_components)
      @view_context = context
      @user = user
      @allowed_components = allowed_components
    end

    def resolve(component)
      # Menu items can be defined via reference (i.e., a custom link item)
      # or using a predefined component (one of `@allowed_components`).
      # In these cases, the components must be defined as follows:
      # - ref:some_custom_link
      # - courses
      if component.is_a? String
        if component.start_with?('ref:')
          # Resolve the referenced menu item, i.e. create the
          # corresponding link from the provided config.
          return custom_reference_for resolved_name(component)
        end

        # Construct the (predefined) component by calling
        # the respective factory method.
        return send(component) if valid?(component)
      end

      # Custom dropdown components, containing custom references, can be
      # defined (inline) as follows:
      # - text: {en: 'Some dropdown text'}
      #   items:
      #     - ref:some_link
      if component.is_a?(Hash)
        custom_dropdown_for resolved_name(component)
      end
    end

    # --- Constructors for custom components --- #

    def custom_reference_for(component)
      config = Xikolo.config.layout.dig('ref', component)

      # Skip the custom reference if no proper configuration is
      # provided, i.e. the link text is not available in any
      # language nor an icon is present.
      return if config.blank?
      return if config['text'].blank? && config['icon'].blank?
      return if config['href'].blank?
      return if config['icon'] && config['title'].blank?

      Navigation::Item.new(
        text: Translations.new(config['text']),
        active: @view_context.current_page?(config.fetch('href')),
        link: {href: config.fetch('href'), target: config['target']},
        icon: {code: config['icon'], aria_label: Translations.new(config['title'])},
        type: config['type'].presence || 'hide-first'
      )
    rescue KeyError
      # If the configuration for a custom reference is
      # invalid or incomplete, it is ignored.
      # The link target/href must be given.
      # The icon is optional for this item type
      # and thus doesn't raise an error when missing.
      # If an icon is given, its aria-label is required.
      nil
    end

    def custom_dropdown_for(component)
      # Skip the custom dropdown if no proper configuration is
      # provided, i.e. no dropdown items exist.
      return if component.blank?
      return if component['items'].blank?

      items = component['items'].map { resolve(_1) }.compact

      Navigation::Item.new(
        text: Translations.new(component.fetch('text')), type: component['type'].presence || 'hide-first'
      ).tap do |dropdown|
        items.each do |item|
          dropdown.with_item(item)
        end
      end
    rescue KeyError
      # If the configuration for a custom dropdown is
      # invalid or incomplete, it is ignored.
      # The dropdown button text must be given.
      nil
    end

    # --- Constructors for predefined components --- #

    def about
      return if @user.logged_in?

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.about', site_name: Xikolo.config.site_name),
        active: @view_context.current_page?(@view_context.page_path(:about)),
        link: {href: @view_context.page_path(:about)},
        type: 'hide-first'
      )
    end

    def administration
      return if @user.anonymous?

      nav = AdminNavigation.items_for(@user)
      return if nav.empty?

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.administration')
      ).tap do |dropdown|
        dropdown.with_items(
          nav.map do |item|
            {
              text: item.text,
              link: {href: item.link},
              active: item.active?(@view_context.request),
              icon: {code: item.icon_class},
            }
          end
        )
      end
    end

    def announcements
      return unless @user.feature?('announcements')

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.news'),
        active: @view_context.current_page?(@view_context.news_index_path),
        link: {href: @view_context.news_index_path},
        type: 'hide-first'
      )
    end

    def channels
      return if @view_context.course_channels.blank?

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.channels'), type: 'hide-last'
      ).tap do |dropdown|
        dropdown.with_items(
          @view_context.course_channels.map do |channel|
            {
              text: channel.name,
              link: {href: @view_context.channel_path(channel.code)},
              active: @view_context.current_page?(@view_context.channel_path(channel.code)),
            }
          end
        )
      end
    end

    def courses
      return unless @user.feature?('course_list')

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.courses'),
        active: @view_context.current_page?(@view_context.courses_path),
        link: {href: @view_context.courses_path},
        type: 'hide-last'
      )
    end

    def courses_megamenu
      Navigation::CoursesMenu.new(user: @user)
    end

    def home
      Navigation::Item.new(
        text: I18n.t(:'header.navigation.home'),
        active: @view_context.current_page?(@view_context.root_path),
        link: {href: @view_context.root_path},
        type: 'hide-first'
      )
    end

    def language_chooser
      return if Xikolo.config.locales['available'].size <= 1

      Navigation::Item.new(
        text: I18n.t(:"languages.name.#{I18n.locale}"),
        icon: {code: 'globe', aria_label: I18n.t(:'header.navigation.choose_language')},
        active: false
      ).tap do |dropdown|
        dropdown.with_items(
          Xikolo.config.locales['available'].map do |locale|
            {
              text: I18n.t(
                :'languages.item',
                name: I18n.t(:"languages.name.#{locale}", locale:),
                foreign: I18n.t(:"languages.name.#{locale}", locale: I18n.locale),
                english: I18n.t(:"languages.name.#{locale}", locale: :en)
              ),
              link: {href: @view_context.url_for(
                @view_context.request.query_parameters.merge('locale' => locale)
              )},
              active: I18n.locale == locale.to_sym,
            }
          end
        )
      end
    end

    def login
      return if @user.logged_in?

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.login'),
        icon: {code: 'user', aria_label: I18n.t(:'header.navigation.login')},
        active: @view_context.current_page?(@view_context.new_session_path),
        link: {href: @view_context.new_session_path}
      )
    end

    def profile
      Navigation::ProfileItem.new(
        user: @user,
        gamification_score:
      )
    end

    def register
      return unless @user.feature?('account.registration')
      return if @user.logged_in?

      Navigation::Item.new(
        text: I18n.t(:'header.navigation.register'),
        active: @view_context.current_page?(@view_context.new_account_path),
        link: {href: @view_context.new_account_path}
      )
    end

    private

    def gamification_score
      return unless Xikolo.config.gamification['enabled']
      return if @user.anonymous?
      return unless @user.feature?('gamification')

      Gamification::Score.where(user_id: @user.id).total
    end

    def resolved_name(component)
      case component
        when /^ref:([a-z_-]+)/
          Regexp.last_match(1)
        else
          component
      end
    end

    def valid?(component)
      # Ensure the method for constructing the (predefined) menu item
      # is declared and the component is allowed.
      return false unless respond_to?(component, true)
      return false unless @allowed_components.include? component

      true
    end
  end
end
