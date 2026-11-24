# frozen_string_literal: true

require 'spec_helper'

describe Course::OptionalItemListPresenter, type: :presenter do
  subject(:presenter) { described_class.new(course, user_id, progresses, current_item_id:) }

  let(:course) { create(:'course_service/course', course_code: 'digital-justice') }
  let(:user_id) { create(:'account_service/user').id }
  let(:current_item_id) { nil }
  let(:week1) { create(:'course_service/section', course:, title: 'Week 1', position: 1) }
  let(:bonus) { create(:'course_service/section', course:, title: 'Bonus', position: 2, optional_section: true) }
  let(:progresses) do
    [week1, bonus].map {|section| {'kind' => 'section', 'resource_id' => section.id} } + [{'kind' => 'course'}]
  end
  let(:items) { presenter.to_a }

  before do
    create(:'course_service/item', section: week1, title: 'Lecture video')
    create(:'course_service/item', :text, section: week1, title: 'Further reading', optional: true)
    create(:'course_service/item', :quiz, section: week1, title: 'Bonus quiz', optional: true,
      submission_deadline: 1.day.ago)
    create(:'course_service/item', section: bonus, title: 'Interview')
  end

  it 'lists the optional items and the items of optional sections, of any type, in course order' do
    expect(items.map(&:title)).to eq ['Further reading', 'Bonus quiz', 'Interview']
  end

  it 'shows optional quizzes with their quiz progress, e.g. locked past their submission deadline' do
    bonus_quiz = items.find {|item| item.title == 'Bonus quiz' }

    expect(bonus_quiz.state).to eq :locked
  end

  context 'with the current item' do
    let(:current_item_id) { CourseService::Item.find_by!(title: 'Interview').id }

    it 'highlights it' do
      expect(items.map(&:state)).to eq %i[default locked current]
    end
  end
end
