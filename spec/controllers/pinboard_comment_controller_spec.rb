# frozen_string_literal: true

require 'spec_helper'

describe PinboardCommentController, type: :controller do
  let(:default_params) { {format: 'json'} }

  let(:course_id) { SecureRandom.uuid }
  let(:course_context) { AccountService::Context.root }
  let(:course) { create(:'course_service/course', :active, id: course_id, course_code: 'the_course', title: 'Test Course') }

  let(:comment_user_id) { SecureRandom.uuid }
  let(:user) { create(:'account_service/user', id: comment_user_id) }
  let(:comment_id) { SecureRandom.uuid }

  before do
    course

    Stub.request(
      :pinboard, :get, "/comments/#{comment_id}"
    ).to_return Stub.json({
      id: comment_id,
    })

    sign_in(user:)
  end

  describe 'POST create' do
    subject(:create_action) { post :create, params: }

    let(:params) do
      default_params.merge(
        course_id:,
        question_id:,
        xikolo_pinboard_comment: comment_params
      )
    end

    let(:question_id) { SecureRandom.uuid }
    let(:comment_params) { {commentable_type:, commentable_id:, text: comment_text} }
    let(:commentable_type) { 'foo' }
    let(:commentable_id) { SecureRandom.uuid }
    let(:comment_text) { 'cool comment' }

    let!(:create_comment) do
      Stub.request(
        :pinboard, :post, '/comments'
      ).to_return Stub.json({})
    end

    context 'not logged in' do
      it 'redirects to the course path' do
        expect(create_action).to redirect_to course_path('the_course')
      end

      it 'does not create the comment' do
        create_action
        expect(create_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access' do
      before { sign_in user: user, permissions: ['course.content.access'] }

      it 'redirects back to the course_question_path' do
        expect(create_action).to redirect_to course_question_path(course_id:, id: question_id)
      end

      it 'creates a comment' do
        create_action
        expect(create_comment).to have_been_requested
      end
    end
  end

  describe 'PUT update' do
    subject(:update_action) { put :update, params: }

    let(:params) do
      default_params.merge(
        id: comment_id,
        course_id:,
        question_id:,
        xikolo_pinboard_comment: comment_params
      )
    end

    let(:question_id) { SecureRandom.uuid }
    let(:comment_params) { {text: new_comment_text} }
    let(:commentable_type) { 'foo' }
    let(:commentable_id) { SecureRandom.uuid }
    let(:new_comment_text) { 'cooler comment' }

    let!(:update_comment) do
      Stub.request(
        :pinboard, :put, "/comments/#{comment_id}",
        body: hash_including(text: new_comment_text)
      ).to_return Stub.json({})
    end

    context 'not logged in' do
      it 'redirects the user back to the course path' do
        expect(update_action).to redirect_to course_path('the_course')
      end

      it 'does not update the comment' do
        update_action
        expect(update_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access' do
      before { sign_in user: user, permissions: ['course.content.access'] }

      it 'redirect to the course question path' do
        expect(update_action).to redirect_to course_question_path(course_id:, id: question_id)
      end

      it 'updates the comment' do
        update_action
        expect(update_comment).to have_been_requested
      end
    end
  end

  describe 'POST block' do
    subject(:block_action) { post :block, params: }

    let(:params) do
      default_params.merge(
        id: comment_id,
        course_id:,
        question_id:,
        text_purpose: 'display'
      )
    end

    let(:question_id) { SecureRandom.uuid }

    let!(:block_comment) do
      Stub.request(
        :pinboard, :put, "/comments/#{comment_id}",
        body: hash_including(workflow_state: 'blocked')
      ).to_return Stub.json({})
    end

    before do
      Stub.request(
        :pinboard, :get, "/comments/#{comment_id}?text_purpose=display"
      ).to_return Stub.json({id: comment_id})
    end

    context 'not logged in' do
      it 'redirects to the course path' do
        expect(block_action).to redirect_to course_path('the_course')
      end

      it 'does not block the comment' do
        block_action
        expect(block_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access' do
      before { sign_in user: user, permissions: ['course.content.access'] }

      it 'redirects to the course root' do
        expect(block_action).to redirect_to root_path
      end

      it 'does not block the comment' do
        block_action
        expect(block_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access and permission to block comment' do
      before { sign_in user: user, permissions: ['course.content.access', 'pinboard.entity.block'] }

      it 'redirects to the course question show page' do
        expect(block_action).to redirect_to(course_question_path(course_id:, id: question_id))
      end

      it 'blocks the comment' do
        block_action
        expect(block_comment).to have_been_requested
      end
    end
  end

  describe 'POST unblock' do
    subject(:unblock_action) { post :unblock, params: }

    let(:params) do
      default_params.merge(
        id: comment_id,
        course_id:,
        question_id:
      )
    end

    let(:question_id) { SecureRandom.uuid }

    let!(:unblock_comment) do
      Stub.request(
        :pinboard, :put, "/comments/#{comment_id}",
        body: hash_including(workflow_state: 'reviewed')
      ).to_return Stub.json({})
    end

    before do
      Stub.request(
        :pinboard, :get, "/comments/#{comment_id}?text_purpose=display"
      ).to_return Stub.json({id: comment_id})
    end

    context 'not logged in' do
      it 'redirects to the course path' do
        expect(unblock_action).to redirect_to course_path('the_course')
      end

      it 'does not unblock the comment' do
        unblock_action
        expect(unblock_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access' do
      before { sign_in user: user, permissions: ['course.content.access'] }

      it 'redirects to the course root' do
        expect(unblock_action).to redirect_to root_path
      end

      it 'does not unblock the comment' do
        unblock_action
        expect(unblock_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access and permission to block comment' do
      before { sign_in user: user, permissions: ['course.content.access', 'pinboard.entity.block'] }

      it 'redirects to the course question path' do
        expect(unblock_action).to redirect_to course_question_path(course_id:, id: question_id)
      end

      it 'unblocks the comment' do
        unblock_action
        expect(unblock_comment).to have_been_requested
      end
    end
  end

  describe 'DELETE destroy' do
    subject(:destroy_action) { delete :destroy, params: }

    let(:params) do
      default_params.merge(
        id: comment_id,
        course_id:,
        question_id:
      )
    end

    let(:question_id) { SecureRandom.uuid }

    let!(:delete_comment) do
      Stub.request(
        :pinboard, :delete, "/comments/#{comment_id}"
      ).to_return Stub.response(status: 204)
    end

    context 'not logged in' do
      it 'redirects to the course path' do
        expect(destroy_action).to redirect_to course_path('the_course')
      end

      it 'does not delete the comment' do
        destroy_action
        expect(delete_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access' do
      before { sign_in user: user, permissions: ['course.content.access'] }

      it 'redirects to the root path' do
        expect(destroy_action).to redirect_to root_path
      end

      it 'does not delete the comment' do
        destroy_action
        expect(delete_comment).not_to have_been_requested
      end
    end

    context 'logged in, with course access and permission to delete comment' do
      before { sign_in user: user, permissions: ['course.content.access', 'pinboard.entity.delete'] }

      it 'redirects to the course question path' do
        expect(destroy_action).to redirect_to course_question_path(course_id:, id: question_id)
      end

      it 'deletes the comment' do
        destroy_action
        expect(delete_comment).to have_been_requested
      end
    end
  end
end
