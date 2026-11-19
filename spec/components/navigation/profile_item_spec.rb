# frozen_string_literal: true

require 'spec_helper'

describe Navigation::ProfileItem, type: :component do
  subject(:component) do
    described_class.new(user:, gamification_score:)
  end

  let(:user_id) { generate(:user_id) }
  let(:gamification_score) { nil }
  let(:masquerated) { false }
  let(:features) { {} }

  describe 'with a logged out user' do
    let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_selector "[aria-label='Profile menu']"
    end
  end

  describe 'with a regular logged in user' do
    let(:session) { create(:'account_service/session') }
    let(:user) do
      CurrentUser::User.new(
        session:,
        context_id: 'root'
      )
    end

    it 'only displays the avatar component' do
      render_inline(component)

      expect(page).to have_css "[title=\"#{user.name}\"]"
      expect(page).to have_no_link 'DEMASQ'
      expect(page).to have_no_text 'XP'
    end

    it 'displays a dropdown with the default menu items' do
      AccountService::Feature.find_by!(name: 'profile').destroy!

      render_inline(component)

      expect(page).to have_css '[data-behaviour=dropdown]'
      expect(page).to have_link 'Dashboard'
      expect(page).to have_link 'Certificates'
      expect(page).to have_link 'Log out'
      expect(page).to have_link 'Achievements'
      expect(page).to have_no_link 'Profile'
    end

    describe 'with the profile feature flipper enabled' do
      it 'displays the profile menu item' do
        render_inline(component)

        expect(page).to have_link 'Profile'
      end
    end

    context 'with the gamification feature' do
      it 'displays the achievements menu item' do
        render_inline(component)

        expect(page).to have_link 'Achievements'
        expect(page).to have_no_text 'XP'
      end

      describe 'the user has gamification points' do
        let(:gamification_score) { 50 }

        it 'displays the gamification points' do
          render_inline(component)

          expect(page).to have_text '50 XP'
        end
      end
    end

    describe 'with a masquerated user' do
      it 'displays the demasq button' do
        session.masquerade!(create(:'account_service/user'))

        render_inline(component)

        expect(page).to have_link 'DEMASQ'
      end
    end

    context 'with custom child components' do
      before do
        xi_config <<~YML
          layout:
            ref:
              dashboard:
                href: '/dashboard'
                text: {de: 'Dashboard'}
                icon: 'dashboard'
              settings:
                href: '/preferences'
                text: {de: 'Einstellungen'}
                icon: 'settings'
          header:
            visible: true
            secondary:
              - profile
          profile:
            - ref:dashboard
            - ref:settings
        YML
      end

      it 'displays the child components' do
        render_inline(component)

        expect(page).to have_link 'Dashboard'
        expect(page).to have_link 'Einstellungen'
        expect(page).to have_css '.fa-dashboard'
        expect(page).to have_css '.fa-settings'
      end

      describe 'with invalid configuration (missing href)' do
        before do
          xi_config <<~YML
            layout:
              ref:
                dashboard:
                  text: {de: 'Dashboard'}
                  icon: 'dashboard'
            header:
              visible: true
              secondary:
                - profile
            profile:
              - ref:dashboard
          YML
        end

        it 'does not render the incorrect item' do
          render_inline(component)

          expect(page).to have_no_link 'Dashboard'
        end
      end
    end
  end
end
