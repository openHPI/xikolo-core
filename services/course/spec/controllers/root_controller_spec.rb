# frozen_string_literal: true

require 'spec_helper'

describe RootController, type: :controller do
  subject { get :index }

  let(:json) { JSON.parse response.body }

  describe '#index' do
    subject { JSON.parse super().body }

    it { is_expected.to have_key 'courses_url' }
    it { is_expected.to have_key 'course_url' }
    it { is_expected.to have_key 'sections_url' }
    it { is_expected.to have_key 'section_url' }
    it { is_expected.to have_key 'items_url' }
    it { is_expected.to have_key 'item_url' }
    it { is_expected.to have_key 'enrollments_url' }
    it { is_expected.to have_key 'enrollment_url' }
    it { is_expected.to have_key 'repetition_suggestions_url' }
    it { is_expected.to have_key 'prerequisite_status_url' }
  end

  describe 'response' do
    describe 'Cache-Control' do
      let(:cache_control) { subject.headers['Cache-Control'].strip.split(/\s*,\s*/) }

      it 'is public cacheable for 5 minutes' do
        expect(cache_control).to match_array %w[public max-age=300]
      end
    end
  end
end
