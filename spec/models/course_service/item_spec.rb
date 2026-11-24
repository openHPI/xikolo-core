# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, type: :model do
  let(:item) { create(:item, item_params) }
  let(:item_params) { {} }
  let(:user) { create(:'account_service/user') }
  let(:other_user) { create(:'account_service/user') }

  describe '(exam content)' do
    %i[video richtext lti_exercise cmi5].each do |type|
      context "with #{type} content" do
        let(:item) { create(:item, type) }

        it 'rejects changing the exercise type to exam' do
          expect(item.update(exercise_type: 'exam')).to be false
          expect(item.errors.details[:exercise_type]).to include(error: :requires_question_pool)
        end
      end
    end
  end

  describe '(single exam per course)' do
    let(:course) { create(:'course_service/course') }
    let(:section) { create(:'course_service/section', course:) }
    let(:quiz) { create(:'quiz_service/quiz', :with_valid_question_pool) }
    let(:exam_item) do
      create(:'course_service/item',
        section:,
        content: quiz,
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
          content: quiz,
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
      let(:item_params) { {content: create(:richtext)} }

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
      let(:item_params) { {content: create(:'quiz_service/quiz'), exercise_type: 'selftest', max_dpoints: 100} }

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
        expect(item.content_type).to eq item.content.class.polymorphic_name
      end

      it 'identifies the content type without loading the content' do
        item.reload.strict_loading!

        expect(item.content_type_name).to eq item.content_type
        expect([item.video?, item.quiz?, item.rich_text?, item.lti_exercise?, item.cmi5?]).to eq(
          %w[Video::Video QuizService::Quiz CourseService::Richtext Lti::Exercise Cmi5::Item]
            .map {|type| type == item.content_type }
        )
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

    context 'with quiz content' do
      subject(:item) { create(:item, content: create(:'quiz_service/quiz'), exercise_type: 'selftest') }

      it_behaves_like 'an item with polymorphic content'
    end

    context 'with CMI5 content' do
      subject(:item) { create(:item, :cmi5) }

      it_behaves_like 'an item with polymorphic content'
    end
  end
end
