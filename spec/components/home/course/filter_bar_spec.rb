# frozen_string_literal: true

require 'spec_helper'

describe Home::Course::FilterBar, type: :component do
  subject(:rendered) do
    render_inline described_class.new(user:)
  end

  let(:user) { nil }

  before do
    xi_config <<~YML
      course_languages: [de, en, fr]
    YML
  end

  describe 'language filter' do
    context 'with no signed in user' do
      context 'with no http accept languages' do
        it 'shows all available course languages sorted alphabetically' do
          expect(rendered).to have_select 'Language', text: "All\nEnglish (English)\nFrench (Français)\nGerman (Deutsch)"
        end
      end

      context 'with http accept languages' do
        before do
          vc_test_request.env['HTTP_ACCEPT_LANGUAGE'] = 'ru, fr'
        end

        it 'brings the http accept languages to the top of the select before a line separator' do
          expect(rendered).to have_select 'Language', text: "All\nFrench (Français)\n──────────\nEnglish (English)\nGerman (Deutsch)"
        end

        it 'does not display http accept languages that are not course languages' do
          expect(rendered).to have_no_content 'Russian (Русский)'
        end

        it 'adds a disabled line separator' do
          expect(rendered).to have_css 'option[value="──────────"][disabled]'
        end
      end

      context 'with regional http accept languages' do
        before do
          vc_test_request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-LI, ru, fr'
        end

        it 'brings the available parent language to the top of the select' do
          expect(rendered).to have_select 'Language', text: "All\nGerman (Deutsch)\nFrench (Français)\n──────────\nEnglish (English)"
        end
      end
    end

    context 'with signed in user' do
      let(:user) do
        Xikolo::Common::Auth::CurrentUser.from_session(
          'user' => {'anonymous' => false,
          'preferred_language' => 'de'}
        )
      end

      context 'with no http accept languages' do
        it 'brings the user preferred language to the first position' do
          expect(rendered).to have_select 'Language', text: "All\nGerman (Deutsch)\n──────────\nEnglish (English)\nFrench (Français)"
        end
      end

      context 'with http accept languages' do
        before do
          vc_test_request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr, es'
        end

        it 'puts the available http accept languages right after the user preferred language' do
          expect(rendered).to have_select 'Language', text: "All\nGerman (Deutsch)\nFrench (Français)\n──────────\nEnglish (English)"
        end

        it 'does not display the user preferred language twice if it is also in the accept header' do
          expect(rendered).to have_content 'German (Deutsch)', count: 1
        end

        context 'with all course languages as preferred by the user' do
          before do
            vc_test_request.env['HTTP_ACCEPT_LANGUAGE'] = 'de, en, fr'
          end

          it 'does not display a line separator' do
            expect(rendered).to have_no_selector 'option[value="──────────"][disabled]'
          end
        end
      end
    end
  end

  describe '(custom) category filter' do
    before do
      invisible_category = create(:cluster, :invisible, id: 'invisible', translations: {en: 'Invisible'})
      create(:classifier, cluster: invisible_category, title: 'not_shown', translations: {en: 'Not shown'})
      visible_category = create(:cluster, :visible, id: 'topics', translations: {en: 'Topic'})
      create(:classifier, cluster: visible_category, title: 'advanced_learner', translations: {en: 'Advanced'})
    end

    it 'lists the visible categories with localized tags' do
      expect(rendered).to have_select 'Topic', text: "All\nAdvanced"
      expect(rendered).to have_no_select 'Invisible'
    end
  end
end
