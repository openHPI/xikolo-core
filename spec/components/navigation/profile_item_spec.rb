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
    let(:user) do
      Xikolo::Common::Auth::CurrentUser.from_session(
        'user' => {
          'anonymous' => true,
        }
      )
    end

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_selector "[aria-label='Profile menu']"
    end
  end

  describe 'with a regular logged in user' do
    let(:user) do
      Xikolo::Common::Auth::CurrentUser.from_session(
        'features' => features,
        'user_id' => user_id,
        'masqueraded' => masquerated,
        'user' => {
          'anonymous' => false,
          'name' => 'John',
        }
      )
    end

    it 'only displays the avatar component' do
      render_inline(component)

      expect(page).to have_css '[title=John]'
      expect(page).to have_no_link 'DEMASQ'
      expect(page).to have_no_content 'XP'
    end

    it 'displays a dropdown with the default menu items' do
      render_inline(component)

      expect(page).to have_css '[data-behaviour=dropdown]'
      expect(page).to have_link 'Dashboard'
      expect(page).to have_link 'Certificates'
      expect(page).to have_link 'Log out'
      expect(page).to have_no_link 'Profile'
      expect(page).to have_no_link 'Achievements'
    end

    describe 'with the profile feature flipper enabled' do
      let(:features) { {'profile' => true} }

      it 'displays the profile menu item' do
        render_inline(component)

        expect(page).to have_link 'Profile'
      end
    end

    context 'with the gamification feature flipper enabled' do
      let(:features) { {'gamification' => true} }

      it 'displays the achievements menu item' do
        render_inline(component)

        expect(page).to have_link 'Achievements'
        expect(page).to have_no_content 'XP'
      end

      describe 'the user has gamification points' do
        let(:gamification_score) { 50 }

        it 'displays the gamification points' do
          render_inline(component)

          expect(page).to have_content '50 XP'
        end
      end
    end

    describe 'with a masquerated user' do
      let(:masquerated) { true }

      it 'displays the demasq button' do
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
