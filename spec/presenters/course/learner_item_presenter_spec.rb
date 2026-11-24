# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerItemPresenter, type: :presenter do
  subject(:presenter) { described_class.new(item, course, current:) }

  let(:course) { create(:'course_service/course', course_code: 'digital-justice') }
  let(:user_id) { create(:'account_service/user').id }
  let(:section) { create(:'course_service/section', course:) }
  let(:item_attrs) { {} }
  let(:current) { false }
  let(:record) { create(:'course_service/item', section:, title: 'Welcome video', **item_attrs) }
  let(:item) { CourseService::Item.user_state(user_id).find(record.id) }

  it 'shows the item' do
    expect(presenter).to have_attributes(
      id: item.id,
      title: 'Welcome video',
      label: 'Video',
      icon: 'video',
      state: :default,
      path: %r{\A/learn/digital-justice/items/\w+\z}
    )
  end

  context 'once visited' do
    before { create(:'course_service/visit', item: record, user_id:) }

    it 'marks it as completed' do
      expect(presenter.state).to eq :completed
    end

    context 'when current' do
      let(:current) { true }

      it 'highlights it, even though completed' do
        expect(presenter.state).to eq :current
      end
    end
  end

  context 'when upcoming' do
    let(:item_attrs) { {start_date: 1.day.from_now} }

    it 'locks it, without a link, as it has no page for the learner' do
      expect(presenter).to have_attributes(state: :locked, path: nil)
    end
  end
end
