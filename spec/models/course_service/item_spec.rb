# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, type: :model do
  let(:item) { create(:item, item_params) }
  let(:item_params) { {} }
  let(:user) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }

  describe '(single exam per course)' do
    let(:course) { create(:'course_service/course') }
    let(:section) { create(:'course_service/section', course:) }
    let(:quiz) { create(:'quiz_service/quiz', :with_valid_question_pool) }
    let(:exam_item) do
      create(:'course_service/item',
        section:,
        content_type: 'quiz',
        content_id: quiz.id,
        exercise_type: 'exam',
        published: false)
    end

    it 'allows the first exam of a course' do
      expect(exam_item).to be_valid
    end

    context 'when the course already has an exam' do
      before { exam_item }

      it 'is invalid and the exam_already_exists message resolves' do
        item = CourseService::Item.new(
          section:,
          content_type: 'quiz',
          content_id: quiz.id,
          exercise_type: 'exam',
          published: false
        )

        expect(item).not_to be_valid
        expect(item.errors.details[:exercise_type].any? {|d| d[:error] == :exam_already_exists }).to be true
        expect(item.errors.full_messages)
          .to include("Exercise type #{I18n.t('errors.messages.exam_already_exists')}")
      end
    end
  end

  describe '#fulfilled_for?' do
    subject(:item_fulfillment) { item.fulfilled_for?(user) }

    context '(items with visit-based fulfillment)' do
      let(:item_params) { {content_type: 'rich_text'} }

      it { is_expected.to be_falsey }

      context 'with visit for other user' do
        before { create(:visit, user: other_user, item:) }

        it { is_expected.to be_falsey }
      end

      context 'with visit' do
        before { create(:visit, user:, item:) }

        it { is_expected.to be_truthy }
      end
    end

    context '(items with result-based fulfillment)' do
      let(:item_params) { {content_type: 'quiz', max_dpoints: 100} }

      it { is_expected.to be_falsey }

      context 'with result for other user' do
        before { create(:result, user: other_user, item:, dpoints: 90) }

        it { is_expected.to be_falsey }
      end

      context 'with result' do
        let(:dpoints) { 10 }

        before { create(:result, user:, item:, dpoints:) }

        it { is_expected.to be_falsey }

        context 'with sufficient score' do
          let(:dpoints) { 90 }

          it { is_expected.to be_truthy }
        end

        context 'for a quiz with zero points' do
          let(:item_params) { super().merge(max_dpoints: 0) }

          it { is_expected.to be_truthy }
        end
      end
    end
  end

  describe '(content)' do
    shared_examples 'an item with polymorphic content' do
      it 'is known by its content' do
        expect(item.content.item).to eq item
      end

      it 'knows the `content_type`' do
        expect(item.content.class.polymorphic_name).to be_in %w[video lti_exercise rich_text]
        expect(item.content_type).to be_in %w[video lti_exercise rich_text]
      end
    end

    context 'with LTI exercise content' do
      subject(:item) { create(:item, :lti_exercise) }

      it_behaves_like 'an item with polymorphic content'
    end

    context 'with video content' do
      subject(:item) { create(:item, :video) }

      it_behaves_like 'an item with polymorphic content'
    end

    context 'with text content' do
      subject(:item) { create(:item, :richtext) }

      it_behaves_like 'an item with polymorphic content'
    end
  end
end
