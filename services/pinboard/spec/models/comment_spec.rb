# frozen_string_literal: true

require 'spec_helper'

describe Comment, type: :model do
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
    subject(:comment) { build(:'pinboard_service/comment') }

    it 'publishes an event for newly created comments' do
      expect(Msgr).to receive(:publish) # Expecting the published event for creating a new question related to the answer
      expect(Msgr).to receive(:publish) do |comment_as_hash, msgr_params|
        expect(comment_as_hash).to be_a(Hash)
        expect(comment_as_hash).to eq comment.decorate.to_event
        expect(msgr_params).to include(to: 'xikolo.pinboard.comment.create')
      end
      comment.save
    end

    it 'pubishes an event for updated comments' do
      comment.save

      expect(Msgr).to receive(:publish) do |updated_comment_as_hash, msgr_params|
        expect(updated_comment_as_hash).to be_a(Hash)
        expect(updated_comment_as_hash).to include('text' => 'Foo is the correct answer')
        expect(msgr_params).to include(to: 'xikolo.pinboard.comment.update')
      end

      comment.text = 'Foo is the correct answer'
      comment.save
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
        end.to change { comment.commentable.public_comments_count }.by(-1)
      end
    end

    describe 'destroying' do
      subject(:deletion) { comment.destroy }

      it 'decreases the public comment count' do
        expect do
          deletion
        end.to change { comment.commentable.public_comments_count }.by(-1)
      end
    end

    describe 'blocking' do
      subject(:blocking) { comment.block! }

      it 'decreases the public comment count' do
        expect do
          blocking
        end.to change { comment.commentable.public_comments_count }.by(-1)
      end
    end

    describe 'auto-blocking' do
      subject(:auto_blocking) { comment.update!(workflow_state: :auto_blocked) }

      it 'decreases the public comment count' do
        expect do
          auto_blocking
        end.to change { comment.commentable.public_comments_count }.by(-1)
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
        end.to change { comment.commentable.question.public_answer_comments_count }.by(-1)
      end
    end

    describe 'destroying' do
      subject(:deletion) { comment.destroy }

      it 'decreases the public answer comment count' do
        expect do
          deletion
        end.to change { comment.commentable.question.public_answer_comments_count }.by(-1)
      end
    end

    describe 'blocking' do
      subject(:blocking) { comment.block! }

      it 'decreases the public answer comment count' do
        expect do
          blocking
        end.to change { comment.commentable.question.public_answer_comments_count }.by(-1)
      end
    end

    describe 'auto-blocking' do
      subject(:auto_blocking) { comment.update!(workflow_state: :auto_blocked) }

      it 'decreases the public answer comment count' do
        expect do
          auto_blocking
        end.to change { comment.commentable.question.public_answer_comments_count }.by(-1)
      end
    end
  end
end
