# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerItems, type: :model do
  subject(:learner_items) { described_class.new(course, user_id, progresses) }

  let(:course) { create(:'course_service/course') }
  let(:user_id) { create(:'account_service/user').id }
  let!(:week1) { create(:'course_service/section', course:, title: 'Week 1', position: 1) }
  let!(:week2) { create(:'course_service/section', course:, title: 'Week 2', position: 2) }
  let!(:draft) { create(:'course_service/section', course:, title: 'Draft', position: 3, published: false) }
  let(:progresses) do
    [week1, week2, draft].map {|section| {'kind' => 'section', 'resource_id' => section.id} } +
      [{'kind' => 'course'}]
  end
  let(:titles) { learner_items.items.map(&:title) }

  before do
    create(:'course_service/item', section: week2, title: 'Week 2 video', position: 1)
    create(:'course_service/item', :quiz, section: week1, title: 'Week 1 quiz', position: 2)
    create(:'course_service/item', section: week1, title: 'Week 1 video', position: 1)
    create(:'course_service/item', section: week1, title: 'Unpublished video', published: false)
    create(:'course_service/item', section: draft, title: 'Draft section video')
    create(:'course_service/item', title: 'Other course video')
  end

  it 'lists the published items of the published sections in course order' do
    expect(titles).to eq ['Week 1 video', 'Week 1 quiz', 'Week 2 video']
  end

  it 'narrows down the items by the given scope' do
    quizzes = learner_items.items(scope: CourseService::Item.quiz)

    expect(quizzes.map(&:title)).to eq ['Week 1 quiz']
  end

  it "selects the learner's state on the items" do
    create(:'course_service/visit', item: CourseService::Item.find_by!(title: 'Week 1 video'), user_id:)

    expect(learner_items.items.map(&:user_state)).to eq %w[visited new new]
  end

  context 'with a section the learner does not take' do
    let(:progresses) { [{'kind' => 'section', 'resource_id' => week1.id}, {'kind' => 'course'}] }

    it 'skips its items' do
      expect(titles).to eq ['Week 1 video', 'Week 1 quiz']
    end
  end

  context 'with a discarded alternative section' do
    let(:progresses) do
      [
        {'kind' => 'section', 'resource_id' => week1.id},
        {'kind' => 'section', 'resource_id' => week2.id, 'discarded' => true},
        {'kind' => 'course'},
      ]
    end

    it 'skips its items' do
      expect(titles).to eq ['Week 1 video', 'Week 1 quiz']
    end
  end

  context 'with a content tree' do
    let(:course) { create(:'course_service/course', :with_content_tree) }

    # Reload the course structure record to recalculate the tree indices.
    before { course.node.reload }

    # The tree orders the items as created, regardless of their position.
    it 'lists the items in the order of the tree' do
      expect(titles).to eq ['Week 1 quiz', 'Week 1 video', 'Week 2 video']
    end
  end
end
