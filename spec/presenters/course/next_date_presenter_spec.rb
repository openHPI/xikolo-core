# frozen_string_literal: true

require 'spec_helper'

describe Course::NextDatePresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(next_date.stringify_keys, with_link:)
  end

  let(:with_link) { true }

  context 'next date "course_start"' do
    let(:next_date) { {resource_type: 'course', type: 'course_start', course_code: 'text', date: '2020-01-01T22:00:00+00:00'} }

    it 'has a human readable description' do
      expect(presenter.description).to eq 'Course starts in'
    end

    it 'has a do_url to the course detail page' do
      expect(presenter.do_url).to eq '/courses/text'
    end

    it 'has a proper date object in timezone' do
      expect(presenter.date_obj).to eq '2020-01-01T22:00:00+00:00'
    end

    context 'without a link' do
      let(:with_link) { false }

      it 'does not have a do_url' do
        expect(presenter.do_url).to be_nil
      end
    end
  end

  context 'next date "section_start"' do
    let(:next_date) { {resource_type: 'section', title: 'Einleitung', type: 'section_start'} }

    it 'has a human readable description' do
      expect(presenter.description).to eq 'Einleitung starts in'
    end

    it 'does not have a do_url' do
      expect(presenter.do_url).to be_nil
    end
  end

  context 'next date "item_submission_deadline"' do
    let(:item_id) { SecureRandom.uuid }
    let(:next_date) do
      {resource_type: 'item', type: 'item_submission_deadline',
                    course_code: 'text', resource_id: item_id,
                    title: 'Week 7: Final Assignment'}
    end

    it 'has a human readable description' do
      expect(presenter.description).to eq 'Submissions for Week 7: Final Assignment ending in'
    end

    it 'has a do_url to the course detail page' do
      expect(presenter.do_url).to eq "/courses/text/items/#{short_uuid(item_id)}"
    end
  end

  context 'next date "item_submission_publishing"' do
    let(:item_id) { SecureRandom.uuid }
    let(:next_date) do
      {resource_type: 'item', type: 'item_submission_publishing',
                    course_code: 'text', resource_id: item_id,
                    title: 'Week 7: Final Assignment'}
    end

    it 'has a human readable description' do
      expect(presenter.description).to eq 'Submissions for Week 7: Final Assignment will be published in'
    end

    it 'does not have a do_url' do
      expect(presenter.do_url).to be_nil
    end
  end
end
