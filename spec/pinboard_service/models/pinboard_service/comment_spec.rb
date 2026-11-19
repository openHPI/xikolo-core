# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Comment, type: :model do
  it 'has a valid factory' do
    expect(create(:'pinboard_service/comment')).to be_valid
  end

  describe 'blocked?' do
    it_behaves_like 'a reportable', :'pinboard_service/comment'
  end

  describe 'resetting the reviewed flag' do
    it_behaves_like 'a reviewed reportable', :'pinboard_service/comment', :text
  end

  context '(event publication)' do
    subject(:comment) { build(:'pinboard_service/comment', commentable:) }

    let(:commentable) do
      create(:'pinboard_service/question', user_id: '00000001-3100-4444-9999-000000000003')
    end

    it 'enqueues a CommentCreateJob for newly created comments' do
      comment.save
      expected_payload = comment.decorate.to_event

      expect(CommentCreateJob).to have_been_enqueued.with(expected_payload)
    end
  end

  describe 'question_title' do
    context 'of question comment' do
      subject(:comment) { create(:'pinboard_service/comment', commentable:) }

      let(:commentable) { create(:'pinboard_service/question') }

      it 'calls #question_title on the question' do
        expect(commentable).to receive(:question_title)
        comment.question_title
      end
    end

    context 'of answer comment' do
      subject(:comment) do
        create(:'pinboard_service/comment', :for_answer, commentable:)
      end

      let(:commentable) { create(:'pinboard_service/answer') }

      it 'calls #question_title on the answer' do
        expect(commentable).to receive(:question_title)
        comment.question_title
      end
    end
  end

  context 'on question' do
    let(:comment) { create(:'pinboard_service/comment') }

    describe 'soft-deletion' do
      subject(:soft_deletion) { comment.soft_delete }

      it 'decreases the public comment count' do
        expect do
          soft_deletion
        end.to change { comment.commentable.public_comments.count }.by(-1)
      end
    end

    describe 'destroying' do
      subject(:deletion) { comment.destroy }

      it 'decreases the public comment count' do
        expect do
          deletion
        end.to change { comment.commentable.public_comments.count }.by(-1)
      end
    end

    describe 'blocking' do
      subject(:blocking) { comment.block! }

      it 'decreases the public comment count' do
        expect do
          blocking
        end.to change { comment.commentable.public_comments.count }.by(-1)
      end
    end

    describe 'auto-blocking' do
      subject(:auto_blocking) { comment.update!(workflow_state: :auto_blocked) }

      it 'decreases the public comment count' do
        expect do
          auto_blocking
        end.to change { comment.commentable.public_comments.count }.by(-1)
      end
    end
  end

  context 'on answer' do
    let(:comment) { create(:'pinboard_service/comment', :for_answer) }

    describe 'soft-deletion' do
      subject(:soft_deletion) { comment.soft_delete }

      it 'decreases the public answer comment count' do
        expect do
          soft_deletion
        end.to change { comment.commentable.question.public_answer_comments.count }.by(-1)
      end
    end

    describe 'destroying' do
      subject(:deletion) { comment.destroy }

      it 'decreases the public answer comment count' do
        expect do
          deletion
        end.to change { comment.commentable.question.public_answer_comments.count }.by(-1)
      end
    end

    describe 'blocking' do
      subject(:blocking) { comment.block! }

      it 'decreases the public answer comment count' do
        expect do
          blocking
        end.to change { comment.commentable.question.public_answer_comments.count }.by(-1)
      end
    end

    describe 'auto-blocking' do
      subject(:auto_blocking) { comment.update!(workflow_state: :auto_blocked) }

      it 'decreases the public answer comment count' do
        expect do
          auto_blocking
        end.to change { comment.commentable.question.public_answer_comments.count }.by(-1)
      end
    end
  end
end
