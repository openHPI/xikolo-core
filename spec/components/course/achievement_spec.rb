# frozen_string_literal: true

require 'spec_helper'

describe Course::Achievement, type: :component do
  subject(:component) { render_inline(described_class.new(achievement, documents)) }

  let(:documents) { Course::DocumentsPresenter.new(user_id: SecureRandom.uuid, course: create(:course), current_user: nil) }
  let(:course) { create(:course) }
  let(:achievement) do
    {
      'name' => 'Sample Achievement',
      'description' => 'This is a sample achievement.',
      'achieved' => achieved,
      'achievable' => achievable,
      'requirements' => requirements,
      'download' => download,
    }
  end
  let(:achieved) { false }
  let(:achievable) { false }
  let(:requirements) { [] }
  let(:download) { nil }

  describe 'rendering the component' do
    context 'with an achieved achievement' do
      let(:achieved) { true }

      it 'renders the achieved state' do
        expect(component).to have_css('.achievement--achieved')
        expect(component).to have_text('Sample Achievement')
        expect(component).to have_text('This is a sample achievement.')
      end
    end

    context 'with an achievable achievement' do
      let(:achievable) { true }

      it 'renders the achievable state' do
        expect(component).to have_css('.achievement--in-progress')
        expect(component).to have_text('Sample Achievement')
        expect(component).to have_text('This is a sample achievement.')
      end
    end

    context 'with an unachievable achievement' do
      it 'renders the achievable state' do
        expect(component).to have_css('.achievement')
        expect(component).to have_text('Sample Achievement')
        expect(component).to have_text('This is a sample achievement.')
      end
    end

    context 'with requirements' do
      let(:requirements) do
        [
          {'description' => 'Requirement 1', 'achieved' => true},
          {'description' => 'Requirement 2', 'achieved' => false},
        ]
      end

      it 'renders the requirements' do
        expect(component).to have_text('Requirement 1')
        expect(component).to have_text('Requirement 2')
      end
    end

    context 'with a download action' do
      let(:download) { {'type' => 'download', 'available' => true, 'url' => '#'} }

      it 'renders the download action' do
        expect(component).to have_link('Download', href: '#')
      end
    end

    context 'with an open badge' do
      before do
        allow(documents).to receive_messages(open_badge_enabled?: true, open_badge?: true)
      end

      let(:achievement) do
        {
          'name' => 'Record of Achievement',
          'type' => 'record_of_achievement',
          'description' => 'Record of achievement with an open badge.',
          'achieved' => true,
          'achievable' => true,
          'requirements' => [
            {'description' => 'Requirement 1', 'achieved' => true},
          ],
          'download' => {'type' => 'download', 'available' => true, 'url' => '#'},
        }
      end

      it 'renders the open badge action' do
        expect(component).to have_text('Gain an Open Badge by completing the course.')
        expect(component).to have_link('Show Open Badge')
      end
    end
  end
end
