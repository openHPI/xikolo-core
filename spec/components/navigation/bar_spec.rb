# frozen_string_literal: true

require 'spec_helper'

describe Navigation::Bar, type: :component do
  subject(:component) { described_class.new user: current_user }

  let(:current_user) { Xikolo::Common::Auth::CurrentUser.from_session(anonymous_session) }
  let(:anonymous_session) do
    {
      'id' => nil,
      'masqueraded' => false,
      'user_id' => '51f544b6-a9c7-4bfe-b76b-43a4441d36c3',
      'features' => {},
      'permissions' => [],
      'user' => {
        'anonymous' => true,
        'language' => I18n.locale,
        'preferred_language' => I18n.locale,
      },
    }
  end

  describe 'custom components' do
    context 'with custom icon-only component' do
      before do
        xi_config <<~YML
          layout:
            ref:
              search:
                href: 'https://example.org/search/content'
                title:
                  en: 'Search'
                  de: 'Suche'
                icon: 'magnifying-glass'
          header:
            visible: true
            primary:
              - ref:search
        YML
      end

      it 'contains one (icon-only) link item per breakpoint' do
        render_inline(component)

        # Desktop view
        expect(page).to have_css '[data-test="desktop"] > * [data-test="hide-first"] > a[aria-label="Search"]', count: 1

        # Responsive "More" dropdowns
        expect(page).to have_css '[data-test="menu-hide-first"] > a[aria-label="Search"]', count: 1
        expect(page).to have_css '[data-test="menu-hide-last"] > a[aria-label="Search"]', count: 1

        # Mobile view
        expect(page).to have_css '[data-test="mobile"] > * a[aria-label="Search"]', count: 1
      end

      context 'without providing a title for the icon' do
        before do
          xi_config <<~YML
            layout:
              ref:
                search:
                  href: 'https://example.org/search/content'
                  icon: 'fa fa-search'
            header:
              visible: true
              primary:
                - ref:search
          YML
        end

        it 'ignores the component' do
          render_inline(component)

          expect(page).to have_no_selector 'a'
        end
      end
    end

    context 'with custom text-only component' do
      before do
        xi_config <<~YML
          layout:
            ref:
              search:
                href: 'https://example.org/search/content'
                text:
                  en: 'Search'
                  de: 'Suche'
          header:
            visible: true
            primary:
              - ref:search
        YML
      end

      it 'contains one (text-only) link item per breakpoint' do
        render_inline(component)

        # Desktop view
        expect(page).to have_css '[data-test="desktop"] > * [data-test="hide-first"] > a', count: 1, exact_text: 'Search'

        # Responsive "More" dropdowns
        expect(page).to have_css '[data-test="menu-hide-first"] > a', count: 1, exact_text: 'Search'
        expect(page).to have_css '[data-test="menu-hide-last"] > a', count: 1, exact_text: 'Search'

        # Mobile view
        expect(page).to have_css '[data-test="mobile"] > * a', count: 1, exact_text: 'Search'
      end
    end

    context 'with invalid configuration for custom component' do
      context 'without href' do
        before do
          xi_config <<~YML
            layout:
              ref:
                search:
                  text:
                    en: 'Search'
                    de: 'Suche'
            header:
              visible: true
              primary:
                - ref:search
          YML
        end

        it 'ignores the component' do
          render_inline(component)

          expect(page).to have_no_selector 'a'
        end
      end

      context 'without text nor icon' do
        before do
          xi_config <<~YML
            layout:
              ref:
                search:
                  href: 'https://example.org/search/content'
            header:
              visible: true
              primary:
                - ref:search
          YML
        end

        it 'ignores the component' do
          render_inline(component)

          expect(page).to have_no_selector 'a'
        end
      end
    end

    context 'with custom dropdown component' do
      before do
        xi_config <<~YML
          layout:
            ref:
              catalogues:
                href: '/pages/catalogues'
                text: {en: 'Course catalogues', es: 'Catalogues des cours'}
              courses:
                href: '/courses'
                text: {en: 'All courses', fr: 'Tous les cours'}
          header:
            visible: true
            primary:
              - text: {en: 'Courses', fr: 'Cours'}
                items:
                  - ref:courses
                  - ref:catalogues
        YML
      end

      it 'contains one dropdown button with the provided text for each breakpoint' do
        render_inline(component)

        # Desktop view
        expect(page).to have_css '[data-test="desktop"] > * [data-test="hide-first"] > button[data-behaviour="dropdown"]', count: 1, exact_text: 'Courses'

        # Responsive "More" dropdowns
        expect(page).to have_css '[data-test="menu-hide-first"] > button[data-behaviour="dropdown"]', count: 1, exact_text: 'Courses'
        expect(page).to have_css '[data-test="menu-hide-last"] > button[data-behaviour="dropdown"]', count: 1, exact_text: 'Courses'

        # Mobile view
        expect(page).to have_css '[data-test="mobile"] > * button[data-behaviour="dropdown"]', count: 1, exact_text: 'Courses'
      end

      it 'contains the provided menu items for each breakpoint' do
        render_inline(component)

        # Desktop view dropdown items
        expect(page).to have_css '[data-test="desktop"] > * [data-test="hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Course catalogues'
        expect(page).to have_css '[data-test="desktop"] > * [data-test="hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'All courses'

        # Responsive "More" dropdowns items
        expect(page).to have_css '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Course catalogues'
        expect(page).to have_css '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'All courses'

        expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Course catalogues'
        expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'All courses'

        # Mobile view
        expect(page).to have_css '[data-test="mobile"] > * [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Course catalogues'
        expect(page).to have_css '[data-test="mobile"] > * [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'All courses'
      end

      it 'marks dropdown and item as active when visiting a page linked by one of the items' do
        with_request_url '/pages/catalogues' do
          render_inline(component)

          within '[data-test="desktop"]' do
            # Item
            expect(page).to have_css '[aria-current=page]', exact_text: 'Course catalogues'

            # Dropdown button
            expect(page).to have_css '.navigation-item__main--active', exact_text: 'Courses'
          end
        end
      end
    end

    context 'with invalid configuration for custom dropdown component' do
      context 'without dropdown items' do
        before do
          xi_config <<~YML
            layout:
              ref:
                catalogues:
                  href: '/pages/catalogues'
                  text: {en: 'Course catalogues', es: 'Catalogues des cours'}
                courses:
                  href: '/courses'
                  text: {en: 'All courses', fr: 'Tous les cours'}
            header:
              visible: true
              primary:
                - text: {en: 'Courses', fr: 'Cours'}
          YML
        end

        it 'ignores the component' do
          render_inline(component)

          expect(page).to have_no_button exact_text: 'Courses'
        end
      end
    end
  end

  describe 'language chooser' do
    let(:request_url) { '/helpdesk' }

    before do
      xi_config <<~YML
        header:
          visible: true
          primary:
            - language_chooser
      YML
    end

    around do |example|
      with_request_url(request_url, &example)
    end

    it 'highlights the current language' do
      render_inline(component)

      # The language chooser is rendered twice, once for small and once for larger screens
      expect(page).to have_css '[aria-haspopup=true]', text: 'English', count: 2
    end

    it 'lists all supported languages with default active language marked' do
      render_inline(component)

      # The language chooser is rendered twice, once for small and once for larger screens
      expect(page).to have_css('a', count: 18)
      expect(page).to have_link '中文', count: 2, href: '/helpdesk?locale=cn'
      expect(page).to have_link 'Deutsch', count: 2, href: '/helpdesk?locale=de'
      expect(page).to have_link 'English', count: 2, href: '/helpdesk?locale=en'
      expect(page).to have_link 'Español', count: 2, href: '/helpdesk?locale=es'
      expect(page).to have_link 'Français', count: 2, href: '/helpdesk?locale=fr'
      expect(page).to have_link 'Nederlands', count: 2, href: '/helpdesk?locale=nl'
      expect(page).to have_link 'Português brasileiro', count: 2, href: '/helpdesk?locale=pt-BR'
      expect(page).to have_link 'Русский', count: 2, href: '/helpdesk?locale=ru'
      expect(page).to have_link 'Українська', count: 2, href: '/helpdesk?locale=uk'

      expect(page).to have_css 'a[aria-current]', text: 'English', count: 2
    end

    it 'marks the currently active locale as active' do
      I18n.with_locale(:fr) do
        render_inline(component)

        expect(page).to have_css 'a[aria-current]', text: 'Français', count: 2
      end
    end

    context 'with existing query parameters' do
      let(:request_url) { '/helpdesk?foo=bar' }

      it 'keeps all existing parameters and adds the locale' do
        render_inline(component)

        expect(page).to have_link 'Deutsch', count: 2, href: '/helpdesk?foo=bar&locale=de'
      end
    end

    context 'with existing query parameters incl. locale' do
      let(:request_url) { '/helpdesk?locale=en&foo=bar' }

      it 'keeps all existing parameters and overwrites the locale' do
        render_inline(component)

        expect(page).to have_link 'Deutsch', count: 2, href: '/helpdesk?foo=bar&locale=de'
      end
    end
  end

  describe 'register' do
    before do
      xi_config <<~YML
        header:
          visible: true
          primary:
            - register
      YML
    end

    it 'ignores the component when native registration is disabled' do
      render_inline(component)

      expect(page).to have_no_selector 'a'
    end

    context 'with native registration enabled' do
      let(:anonymous_session) do
        super().merge('features' => {'account.registration' => true})
      end

      it 'contains the sign up link' do
        render_inline(component)

        expect(page).to have_content 'Sign up'
        expect(page).to have_link(href: '/account/new')
      end
    end
  end

  describe 'responsive bar' do
    before do
      xi_config <<~YML
        layout:
          ref:
            courses:
              href: 'https://example.org/courses'
              text:
                en: 'Courses'
              type: 'hide-last'
            channels:
              href: 'https://example.org/channels'
              text:
                en: 'Channels'
              type: 'hide-last'
            about:
              href: 'https://example.org/about'
              text:
                en: 'About'
              type: 'hide-first'
            news:
              href: 'https://example.org/news'
              text:
                en: 'News'
              type: 'hide-first'
        header:
          visible: true
          primary:
            - ref:courses
            - ref:channels
            - ref:about
            - ref:news
      YML
    end

    it "has two 'More' dropdowns for each breakpoint (hide-last, hide-first), each with their corresponding items" do
      render_inline(component)

      expect(page).to have_css '[data-test="menu-hide-first"]', text: 'More', count: 1

      expect(page).to have_no_selector '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', exact_text: 'Courses'
      expect(page).to have_no_selector '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', exact_text: 'Channels'

      expect(page).to have_css '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'About'
      expect(page).to have_css '[data-test="menu-hide-first"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'News'

      expect(page).to have_css '[data-test="menu-hide-last"]', text: 'Menu', count: 1

      expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Courses'
      expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'Channels'
      expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'About'
      expect(page).to have_css '[data-test="menu-hide-last"] > [data-behaviour="menu-dropdown"] > * a', count: 1, exact_text: 'News'
    end

    context 'with only one item inside the dropdown' do
      before do
        xi_config <<~YML
          layout:
            ref:
              courses:
                href: 'https://example.org/courses'
                text:
                  en: 'Courses'
                type: 'hide-last'
          header:
            visible: true
            primary:
              - ref:courses
        YML
      end

      it "displays the item but not in a 'More' dropdown" do
        render_inline(component)

        expect(page).to have_no_selector '[data-test="menu-hide-last"]', text: 'Menu'
        expect(page).to have_link(href: 'https://example.org/courses', text: 'Courses')
      end
    end
  end
end
