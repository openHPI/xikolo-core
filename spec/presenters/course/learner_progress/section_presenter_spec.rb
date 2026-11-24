# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerProgress::SectionPresenter do
  subject(:section) { described_class.new(progress, course, current_item_id:, locked_item_ids:) }

  let(:current_item_id) { nil }
  let(:locked_item_ids) { [] }

  let(:course) { build(:'course_service/course', course_code: 'digital-justice') }
  let(:progress) do
    {
      'resource_id' => '00000002-3100-4444-9999-000000000001',
      'title' => 'Week 1',
      'alternative_state' => 'none',
      'available' => true,
      'items' => [item],
    }
  end
  let(:item) do
    {
      'id' => '00000003-3100-4444-9999-000000000001',
      'title' => 'Welcome video',
      'content_type' => 'Video::Video',
      'exercise_type' => nil,
      'user_state' => 'new',
    }
  end

  it { expect(section.id).to eq '00000002-3100-4444-9999-000000000001' }
  it { expect(section.title).to eq 'Week 1' }
  it { is_expected.to be_visible }
  it { is_expected.not_to be_expanded }
  it { is_expected.not_to be_locked }
  it { is_expected.not_to be_exam }

  context 'with an exam locked until the learner reached the required course progress among other items' do
    subject(:section) { described_class.new(progress, course, exam_unlock_percentage: 70) }

    let(:progress) { super().merge('items' => [item, exam]) }
    let(:exam) do
      {'id' => '00000003-3100-4444-9999-000000000002', 'title' => 'Final exam', 'content_type' => 'QuizService::Quiz',
       'exercise_type' => 'exam', 'user_state' => 'new'}
    end

    it 'can be opened for the other items' do
      expect(section).not_to be_locked
      expect(section.exam_unlock_percentage).to be_nil
    end
  end

  context 'with only exams' do
    let(:item) { super().merge('content_type' => 'QuizService::Quiz', 'exercise_type' => 'exam') }

    it { is_expected.to be_exam }
    it { is_expected.to have_attributes(total_items_count: 0) }

    it 'tells no course progress to unlock the exam, as it is not locked' do
      expect(section.exam_unlock_percentage).to be_nil
    end

    it { is_expected.not_to be_locked }

    context 'when locked until the learner reached the required course progress' do
      subject(:section) { described_class.new(progress, course, exam_unlock_percentage: 70) }

      it 'tells the course progress needed to unlock the exam' do
        expect(section.exam_unlock_percentage).to eq 70
      end

      it { is_expected.to be_locked }
    end
  end

  describe 'progress' do
    let(:progress) { super().merge('items' => [item, item.merge('id' => '00000003-3100-4444-9999-000000000002')]) }

    it 'counts the completed items' do
      expect(section).to have_attributes(completed_items_count: 0, total_items_count: 2)
      expect(section).not_to be_completed
    end

    context 'with some items completed' do
      let(:progress) do
        super().merge('items' => [item.merge('user_state' => 'visited'),
                                  item.merge('id' => '00000003-3100-4444-9999-000000000002')])
      end

      it { is_expected.to have_attributes(completed_items_count: 1, total_items_count: 2) }
      it { is_expected.not_to be_completed }
    end

    context 'with all items completed' do
      let(:progress) do
        super().merge('items' => [item.merge('user_state' => 'visited'),
                                  item.merge('id' => '00000003-3100-4444-9999-000000000002', 'user_state' => 'visited')])
      end

      it { is_expected.to have_attributes(completed_items_count: 2, total_items_count: 2) }
      it { is_expected.to be_completed }
    end

    context 'with all mandatory items completed' do
      let(:progress) do
        super().merge('items' => [item.merge('user_state' => 'visited'),
                                  item.merge('id' => '00000003-3100-4444-9999-000000000002', 'optional' => true)])
      end

      it 'ignores optional items' do
        expect(section).to have_attributes(completed_items_count: 1, total_items_count: 1)
        expect(section).to be_completed
      end
    end

    context 'with an exam' do
      let(:progress) do
        super().merge('items' => [
          item.merge('user_state' => 'visited'),
          item.merge('id' => '00000003-3100-4444-9999-000000000002', 'content_type' => 'QuizService::Quiz',
            'exercise_type' => 'exam', 'user_state' => 'graded', 'max_points' => 20.0, 'user_points' => 20.0,
            'pass_percentage' => 50),
        ])
      end

      it 'ignores it, like the course progress' do
        expect(section).to have_attributes(completed_items_count: 1, total_items_count: 1)
        expect(section).to be_completed
      end
    end
  end

  context 'with the current item' do
    let(:current_item_id) { '00000003-3100-4444-9999-000000000001' }

    it { is_expected.to be_expanded }
  end

  context 'for the parent of alternative sections' do
    let(:progress) { super().merge('alternative_state' => 'parent') }

    it { is_expected.not_to be_visible }
  end

  context 'for an unavailable section' do
    let(:progress) { super().except('items').merge('available' => false) }

    it 'lists no items' do
      expect(section.items).to eq []
    end

    it { is_expected.to be_locked }
    it { is_expected.not_to be_completed }
  end

  describe 'item' do
    subject(:presented) { section.items.first }

    it 'has the item title, type label and icon' do
      expect(presented).to have_attributes(title: 'Welcome video', label: 'Video', icon: 'video')
    end

    it 'links to the item' do
      expect(presented.path).to eq "/learn/digital-justice/items/#{UUID4('00000003-3100-4444-9999-000000000001').to_s(format: :base62)}"
    end

    it 'is not completed before being visited' do
      expect(presented.state).to eq :default
    end

    it 'has no call to action' do
      expect(presented.action_label).to be_nil
    end

    context 'once visited' do
      let(:item) { super().merge('user_state' => 'visited') }

      it { expect(presented.state).to eq :completed }
    end

    context 'for a quiz with a sufficient score' do
      let(:item) do
        super().merge('content_type' => 'QuizService::Quiz', 'exercise_type' => 'main', 'user_state' => 'graded',
          'max_points' => 10.0, 'user_points' => 6.0)
      end

      it { expect(presented).to have_attributes(label: 'Graded Test', state: :completed) }
    end

    context 'for an exam' do
      let(:item) do
        super().merge('content_type' => 'QuizService::Quiz', 'exercise_type' => 'exam', 'user_state' => 'graded',
          'max_points' => 10.0, 'pass_percentage' => 70)
      end

      context 'at its pass percentage' do
        let(:item) { super().merge('user_points' => 7.0) }

        it { expect(presented.state).to eq :completed }

        context 'when current' do
          let(:current_item_id) { item['id'] }

          it 'shows it as passed rather than as the current item' do
            expect(presented).to have_attributes(state: :completed, action_label: nil)
          end
        end
      end

      context 'below its pass percentage, though with a sufficient score for other quizzes' do
        let(:item) { super().merge('user_points' => 6.5) }

        it 'is failed, without a call to action if it cannot be retaken' do
          expect(presented).to have_attributes(state: :failed, action_label: nil)
        end

        context 'when it can be retaken' do
          subject(:section) { described_class.new(progress, course, retakable_item_ids: [item['id']]) }

          it { expect(presented).to have_attributes(state: :failed, action_label: 'Retake') }
        end

        context 'when current' do
          let(:current_item_id) { item['id'] }

          it 'shows it as failed rather than as the current item' do
            expect(presented).to have_attributes(state: :failed, action_label: nil)
          end

          context 'when it can be retaken' do
            subject(:section) do
              described_class.new(progress, course, current_item_id:, retakable_item_ids: [item['id']])
            end

            it { expect(presented).to have_attributes(state: :failed, action_label: 'Retake') }
          end
        end
      end

      context 'when visited but not submitted, as the current item' do
        let(:item) { super().merge('user_state' => 'visited', 'user_points' => nil) }
        let(:current_item_id) { item['id'] }

        it { expect(presented).to have_attributes(state: :current, action_label: 'Continue') }
      end
    end

    context 'for a quiz with a low score' do
      let(:item) do
        super().merge('content_type' => 'QuizService::Quiz', 'exercise_type' => 'main', 'user_state' => 'graded',
          'max_points' => 10.0, 'user_points' => 2.0)
      end

      it { expect(presented.state).to eq :default }
    end

    context 'for a cmi5 item without points' do
      let(:item) { super().merge('content_type' => 'Cmi5::Item', 'max_points' => nil, 'user_state' => 'visited') }

      it 'is completed once visited' do
        expect(presented.state).to eq :completed
      end
    end

    context 'for a cmi5 item with points' do
      let(:item) { super().merge('content_type' => 'Cmi5::Item', 'max_points' => 10.0, 'user_state' => 'visited') }

      it 'is not completed before being submitted' do
        expect(presented.state).to eq :default
      end
    end

    context 'when locked' do
      let(:locked_item_ids) { ['00000003-3100-4444-9999-000000000001'] }

      it 'is locked, but still links to the item explaining the lock' do
        expect(presented.state).to eq :locked
        expect(presented.path).to start_with '/learn/digital-justice/items/'
      end

      context 'once completed' do
        let(:item) { super().merge('user_state' => 'visited') }

        it { expect(presented.state).to eq :completed }
      end

      context 'when current' do
        let(:current_item_id) { '00000003-3100-4444-9999-000000000001' }

        it { expect(presented.state).to eq :current }
      end
    end

    context 'when current' do
      let(:current_item_id) { '00000003-3100-4444-9999-000000000001' }

      it 'is the first item to start with before being visited' do
        expect(presented).to have_attributes(current?: true, state: :current, action_label: 'Start')
      end

      context 'once visited' do
        let(:item) { super().merge('user_state' => 'visited') }

        it 'continues at the item, even though completed' do
          expect(presented).to have_attributes(state: :current, action_label: 'Continue')
        end
      end
    end
  end
end
