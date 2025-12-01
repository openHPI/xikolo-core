# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Question, type: :model do
  subject(:question) { build(:'pinboard_service/question') }

  it 'has a valid factory' do
    expect(question).to be_valid
  end

  it 'has a valid question_with_accepted_answer factory' do
    expect(build(:'pinboard_service/question_with_accepted_answer')).to be_valid
  end

  it 'is invalid with no course_id' do
    question.course_id = nil
    expect(question).not_to be_valid
  end

  describe 'blocked?' do
    it_behaves_like 'a reportable', :'pinboard_service/question'
  end

  describe 'resetting the reviewed flag' do
    it_behaves_like 'a reviewed reportable', :'pinboard_service/question', :text
    it_behaves_like 'a reviewed reportable', :'pinboard_service/question', :title
  end

  context 'scopes' do
    context 'unanswered' do
      subject { PinboardService::Question.unanswered }

      let!(:unanswered_questions) { create_list(:'pinboard_service/question', 3) }

      before do
        # And a few answered questions
        create_list(:'pinboard_service/question_with_accepted_answer', 3)
      end

      it { is_expected.to match_array unanswered_questions }
    end
  end

  context '(subscriptions)' do
    let!(:question) { create(:'pinboard_service/question', :with_subscriptions, subscription_count: 3) }

    it 'deletes associated subscriptions when removed' do
      expect do
        question.destroy!
      end.to change(PinboardService::Subscription, :count).from(3).to(0)
    end
  end

  context '(event publication)' do
    describe 'create question' do
      it 'publishes an event for newly created question' do
        expect(Msgr).to receive(:publish) do |event, opts|
          attrs = {
            id: question.id,
            created_at: question.created_at.iso8601,
            updated_at: question.updated_at.iso8601,
            title: question.title,
            text: question.text,
            video_timestamp: question.video_timestamp,
            video_id: question.video_id,
            user_id: question.user_id,
            accepted_answer_id: question.accepted_answer_id,
            course_id: question.course_id,
            discussion_flag: question.discussion_flag,
            votes: question.votes_sum,
            views: question.watch_count,
            attachment_url: nil,
            sticky: question.sticky,
            deleted: question.deleted,
            closed: question.closed,
            implicit_tags: question.implicit_tags.to_a.map do |tag|
                             {name: tag.name, referenced_resource: tag.referenced_resource}
                           end,
            user_tags: question.explicit_tags.to_a.map(&:name),
            technical: question.technical?,
            abuse_report_state: 'new',
            abuse_report_count: 0,
          }
          expect(event).to eq attrs
          expect(opts).to eq to: 'xikolo.pinboard.question.create'
        end
        question.save
      end
    end

    describe 'update question' do
      let(:accepted_answer) { build(:'pinboard_service/answer', question:) }

      it 'publishes an event for updated question' do
        question.save
        expect(Msgr).to receive(:publish)
          .with(hash_including(title: 'A really good Foo question?'),
            to: 'xikolo.pinboard.question.update')
        question.title = 'A really good Foo question?'
        question.save
      end

      it 'publishes an event for an accepted answer' do
        question.accepted_answer = accepted_answer
        question.save

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq \
            id: question.id,
            title: question.title,
            text: question.text,
            video_timestamp: question.video_timestamp,
            video_id: question.video_id,
            user_id: question.user_id,
            accepted_answer_id: accepted_answer.id,
            accepted_answer_user_id: accepted_answer.user_id,
            course_id: question.course_id,
            discussion_flag: question.discussion_flag,
            created_at: question.created_at.iso8601,
            updated_at: question.updated_at.iso8601,
            votes: question.votes_sum,
            views: question.watch_count,
            attachment_url: nil,
            sticky: question.sticky,
            deleted: question.deleted,
            closed: question.closed,
            implicit_tags: question.implicit_tags,
            user_tags: question.explicit_tags,
            technical: question.technical?,
            abuse_report_state: 'new',
            abuse_report_count: 0
          expect(opts).to eq to: 'xikolo.pinboard.question.update'
        end
        question.save
      end
    end
  end

  context 'sum up votes' do
    let(:question) { create(:'pinboard_service/question') }

    before { create(:'pinboard_service/vote', votable_id: question.id, votable_type: question.class.name, value: 1, user_id: '00000001-3100-4444-9999-000000000001') }

    it 'calculates positive votes correctly' do
      create(:'pinboard_service/vote', votable_id: question.id, votable_type: question.class.name, value: 1, user_id: '00000001-3100-4444-9999-000000000002')
      expect(question.votes_sum).to eq(2)
    end

    it 'calculates negative votes correctly' do
      create(:'pinboard_service/vote', votable_id: question.id, votable_type: question.class.name, value: -1, user_id: '00000001-3100-4444-9999-000000000002')
      create(:'pinboard_service/vote', votable_id: question.id, votable_type: question.class.name, value: -1, user_id: '00000001-3100-4444-9999-000000000003')
      expect(question.votes_sum).to eq(-1)
    end
  end

  describe 'sorting' do
    let!(:question1) { create(:'pinboard_service/question') }
    let!(:question2) { create(:'pinboard_service/question') }
    let!(:question3) { create(:'pinboard_service/question') }
    let!(:question4) { create(:'pinboard_service/question') }

    context 'by sum of votes, same votes chronologically' do
      before do
        create(:'pinboard_service/vote', votable_id: question1.id,
          votable_type: question1.class.name,
          value: 1,
          user_id: '00000001-3100-4444-9999-000000000001')
        create(:'pinboard_service/vote', votable_id: question2.id,
          votable_type: question1.class.name,
          value: -1,
          user_id: '00000001-3100-4444-9999-000000000001')
      end

      context 'descending' do
        subject { PinboardService::Question.default_order.order_by_votes(:desc).pluck :id }

        let(:right_order) { [question1.id, question3.id, question4.id, question2.id] }

        it { is_expected.to eq right_order }

        it { is_expected.to match(right_order) }
      end

      context 'ascending' do
        subject { PinboardService::Question.default_order.order_by_votes(:asc).pluck :id }

        let(:right_order) { [question2.id, question3.id, question4.id, question1.id] }

        it { is_expected.to eq right_order }

        it { is_expected.to match(right_order) }
      end
    end

    context 'by sticky flag' do
      subject { PinboardService::Question.default_order.pluck :id }

      before { question2.update sticky: true }

      its(:first) { is_expected.to eq question2.id }

      context 'together with other orderings' do
        subject { PinboardService::Question.default_order.order_by_votes(:asc).pluck :id }

        before do
          create(:'pinboard_service/vote', votable_id: question1.id,
            votable_type: question1.class.name,
            value: 1,
            user_id: '00000001-3100-4444-9999-000000000001')
          create(:'pinboard_service/vote', votable_id: question3.id,
            votable_type: question1.class.name,
            value: -1,
            user_id: '00000001-3100-4444-9999-000000000001')
        end

        let(:right_order) { [question2.id, question3.id, question4.id, question1.id] }

        # even though question1 has the highest vote, question2 should be first
        it { is_expected.to eq right_order }
      end
    end
  end

  describe '.by_tags' do
    let!(:question_with_tags) { create(:'pinboard_service/question_with_tags') }

    before do
      # And a question without tags
      create(:'pinboard_service/question')
    end

    it 'retrieves the tagged question when using the right tag' do
      tag_id = question_with_tags.tags.first.id
      expect(PinboardService::Question.by_tags([tag_id])).to eq [question_with_tags]
    end

    it 'retrieves the questions fitting all tags' do
      tags = question_with_tags.tags
      expect(PinboardService::Question.by_tags(tags.map(&:id))).to eq [question_with_tags]
    end

    it 'returns nothing for an unused tag' do
      tag = PinboardService::Tag.create course_id: '00000001-3300-4444-9999-000000000002', name: 'Foo'
      expect(PinboardService::Question.by_tags([tag.id])).to eq []
    end
  end

  describe '.by_tag_names' do
    let(:course_id) { '00000001-3300-4444-9999-000000000001' }
    let(:tag1) { create(:'pinboard_service/explicit_tag', name: 'tag 1', course_id:) }
    let(:tag2) { create(:'pinboard_service/explicit_tag', name: 'tag 2', course_id:) }
    let(:tag3) { create(:'pinboard_service/explicit_tag', name: 'tag 3', course_id:) }

    let(:first_question_with_tags_1_and_2)  { create(:'pinboard_service/question', course_id:, tags: [tag1, tag2], title: 'With tags 1 and 2') }
    let(:second_question_with_tags_1_and_2) { create(:'pinboard_service/question', course_id:, tags: [tag1, tag2], title: 'Also with tags 1 and 2') }
    let(:question_with_tags_1_and_2_and_3) { create(:'pinboard_service/question', course_id:, tags: [tag1, tag2, tag3], title: 'With tags 1, 2 and 3') }
    let(:question_with_tags_2_and_3) { create(:'pinboard_service/question', course_id:, tags: [tag2, tag3], title: 'Only with tags 2 and 3') }

    before do
      first_question_with_tags_1_and_2; second_question_with_tags_1_and_2
      question_with_tags_1_and_2_and_3; question_with_tags_2_and_3
    end

    context 'with existing tag names' do
      subject(:tagged) { described_class.by_tag_names [tag1.name, tag2.name], course_id: }

      it { is_expected.to be_a ActiveRecord::Relation }

      it 'has 3 items' do
        expect(tagged.size).to eq(3)
      end

      it { is_expected.to contain_exactly(first_question_with_tags_1_and_2, second_question_with_tags_1_and_2, question_with_tags_1_and_2_and_3) }
    end

    context 'with a non existing tag name' do
      subject(:tagged) { described_class.by_tag_names [tag1.name, 'keks'], course_id: }

      it { is_expected.to be_a ActiveRecord::Relation }

      it 'has no items' do
        expect(tagged.size).to eq(0)
      end
    end
  end

  describe '#soft_delete' do
    let!(:question) { create(:'pinboard_service/question') }
    let(:action) { -> { question.soft_delete } }

    it 'does not delete the question' do
      expect { action.call }.not_to change(PinboardService::Question, :count)
    end

    it 'sets question to deleted' do
      expect { action.call }.to change(question, :deleted).from(false).to(true)
    end

    context 'with subscription' do
      before { create_list(:'pinboard_service/subscription', 5, question_id: question.id) }

      it 'deletes the corresponding subscriptions' do
        expect { action.call }.to change(PinboardService::Subscription, :count).from(5).to(0)
      end
    end

    context 'with answers' do
      let!(:answer) { create(:'pinboard_service/answer', question:) }

      it 'does not delete the corresponding answers' do
        expect { action.call }.not_to change(PinboardService::Answer, :count)
      end

      it 'sets corresponding answers to deleted' do
        expect { action.call }.to change { answer.reload.deleted }.from(false).to(true)
      end

      context 'with answer comments' do
        let!(:answer_comment) { create(:'pinboard_service/comment', :for_answer, answer:) }

        it 'sets the answers comment to deleted' do
          expect { action.call }.to change { answer_comment.reload.deleted }.from(false).to(true)
        end
      end
    end

    context 'with comments' do
      let!(:comment) { create(:'pinboard_service/comment', question:) }

      it 'does not delete the corresponding comment' do
        expect { action.call }.not_to change(PinboardService::Comment, :count)
      end

      it 'sets corresponding comment to deleted' do
        expect { action.call }.to change { comment.reload.deleted }.from(false).to(true)
      end
    end
  end

  describe '#before_save' do
    let!(:question) { create(:'pinboard_service/question') }

    describe 'creation' do
      it 'has a text_hash' do
        expect(question.text_hash).not_to be_nil
      end
    end

    describe 'updating' do
      let(:action) { -> { question.update text: 'test' } }

      it 'updates the text_hash' do
        expect { action.call }.to change(question, :text_hash)
      end
    end
  end

  describe 'question_title' do
    let(:question) { create(:'pinboard_service/question') }

    it 'returns the title (needed for abuse reports)' do
      expect(question.question_title).to eq question.title
    end
  end

  describe 'course_ident' do
    subject { question.course_ident }

    let(:course_id) { SecureRandom.uuid }

    context 'with course_id' do
      let(:question) { create(:'pinboard_service/question', course_id:) }

      it { is_expected.to eq question.course_id }
    end
  end

  describe '#public_answers_count' do
    subject { question.public_answers_count }

    let(:question) { create(:'pinboard_service/question') }

    it { is_expected.to eq 0 }

    context 'with an answer' do
      let(:question) { create(:'pinboard_service/question_with_accepted_answer') }

      it { is_expected.to eq 1 }
    end
  end

  describe '#public_comments_count' do
    subject { question.public_comments.count }

    let(:question) { create(:'pinboard_service/question') }

    it { is_expected.to eq 0 }

    context 'with a comment' do
      let(:question) { create(:'pinboard_service/question_with_comment') }

      it { is_expected.to eq 1 }
    end
  end

  describe '#public_answer_comments_count' do
    subject { question.public_answer_comments.count }

    let(:question) { create(:'pinboard_service/question') }

    it { is_expected.to eq 0 }

    context 'with an answer comment' do
      let(:question) { create(:'pinboard_service/question_with_commented_answer') }

      it { is_expected.to eq 1 }
    end
  end
end
