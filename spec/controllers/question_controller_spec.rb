# frozen_string_literal: true

require 'spec_helper'

describe QuestionController, type: :controller do
  let(:question_id) { '00000002-3500-4444-9999-000000000001' }
  let(:course_id) { '00000001-3300-4444-9999-000000000001' }
  let(:course_code) { 'test' }
  let(:user_id) { '00000000-0000-4444-9999-000000000001' }
  let(:permissions) { ['course.content.access.available'] }
  let(:author_id) { '00000000-0000-4444-9999-000000000001' }
  let(:closed) { nil }

  let(:update_params) do
    {
      id: question_id,
      title: 'SQL',
      text: 'Ich verstehe wirklich nicht, was dieses SQL sein soll?',
      video_timestamp: nil,
      video_id: nil,
      user_id:,
      accepted_answer_id: nil,
      course_id:,
      learning_room_id: nil,
      created_at: nil,
      updated_at: nil,
      votes: nil,
      answer_count: nil,
      user_tags: nil,
      implicit_tags: nil,
      comment_count: nil,
      vote_value_for_requested_user: nil,
      read: nil,
      views: nil,
      answer_comment_count: nil,
      sticky: nil,
      deleted: false,
      closed:,
    }
  end

  let(:question_title) { 'SQL' }
  let(:question_text) { 'Ich verstehe wirklich nicht, was dieses SQL sein soll?' }
  let(:question_create_attrs) do
    {title: question_title,
                                 text: question_text,
                                 user_id: author_id,
                                 course_id:}
  end
  let(:request_context_id) { course_context_id }
  let(:course_params) do
    {
      id: course_id,
      title: 'Test Course',
      description: 'A Test Course.',
      status: 'active',
      course_code:,
      start_date: DateTime.new(2013, 7, 12),
      end_date: DateTime.new(2013, 8, 19),
      abstract: 'Test Course abstract.',
      lang: 'en',
      context_id: course_context_id,
    }
  end

  let(:update_question_stub) do
    Stub.request(
      :pinboard, :put, "/questions/#{question_id}",
      body: hash_including(update_params)
    ).to_return Stub.json(
      update_params.merge(implicit_tags: [])
    )
  end

  before do
    Stub.service(:account, session_url: '/sessions/{id}')
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({id: user_id})

    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      sections_url: '/sections'
    )
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json(course_params)

    Stub.service(:pinboard, implicit_tags_url: '/implicit_tags')
    Stub.request(
      :pinboard, :post, '/questions',
      body: hash_including(
        title: 'SQL',
        text: 'Ich verstehe wirklich nicht, was dieses SQL sein soll?',
        user_id: '00000000-0000-4444-9999-000000000001',
        course_id: '00000001-3300-4444-9999-000000000001',
        tag_names: [],
        question_url: "http://test.host/courses/#{course_id}/question/{id}"
      )
    ).to_return Stub.json({
      id: question_id,
      title: question_title,
      text: question_text,
      user_id: author_id,
      course_id:,
      implicit_tags: [],
    })

    Stub.request(
      :pinboard, :get, "/questions/#{question_id}",
      query: hash_including({})
    ).to_return Stub.json({
      id: question_id,
      title: 'SQL',
      text: 'Ich verstehe wirklich nicht, was dieses SQL sein soll?',
      user_id: author_id,
      course_id:,
      implicit_tags: [],
    })

    Stub.request(
      :pinboard, :get, '/subscriptions',
      query: {user_id:, question_id:}
    ).to_return Stub.json([])

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:}
    ).to_return Stub.json([
      {
        id: '00000000-0000-1111-9999-000000000001',
        user_id:,
        course_id:,
      },
    ])
    Stub.request(
      :course, :get, '/sections',
      query: {course_id:}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/sections',
      query: {course_id:, include_alternatives: true}
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/comments',
      query: hash_including(commentable_id: question_id, commentable_type: 'Question', per_page: '250')
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/explicit_tags',
      query: {question_id:}
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/implicit_tags',
      query: {name: 'Technical Issues', course_id:}
    ).to_return Stub.json([
      {id: '00000001-3500-4444-9999-000000000001', name: 'Technical Issues', course_id:},
    ])
    Stub.request(
      :pinboard, :get, '/answers',
      query: hash_including(question_id:, vote_value_for_user_id: user_id, per_page: '250')
    ).to_return Stub.json([])

    update_question_stub
  end

  context 'while not logged in' do
    describe 'show' do
      it 'redirects to root' do
        get :show, params: {id: question_id, course_id:}
        expect(response).to have_http_status :found
        expect(response).to redirect_to course_url('test')
      end
    end

    describe 'edit' do
      it 'responds' do
        get :edit, params: {id: question_id, course_id:}
        expect(response).to have_http_status :found
        expect(response).to redirect_to course_url('test')
      end
    end

    describe 'delete' do
      it 'responds' do
        get :destroy, params: {id: question_id, course_id:}
        expect(response).to have_http_status :found
        expect(response).to redirect_to course_url('test')
      end
    end
  end

  context 'while logged in' do
    let(:user) { stub_user id: user_id, language: 'en', permissions: }

    before { user }

    describe 'create' do
      it 'responds' do
        get :create, params: {
          id: question_id,
          course_id:,
          xikolo_pinboard_question: question_create_attrs,
        }

        expect(response).to have_http_status :found
        expect(response).to redirect_to course_pinboard_index_path(course_id)
      end
    end

    describe 'show' do
      it 'responds' do
        get :show, params: {id: question_id, course_id:}
        expect(response).to have_http_status :ok
      end

      context 'with disabled pinboard' do
        let(:course_params) { super().merge(pinboard_enabled: false) }

        it 'raises an error' do
          expect do
            get :show, params: {id: question_id, course_id:}
          end.to raise_error(AbstractController::ActionNotFound)
        end
      end

      context 'with a different course' do
        subject(:action) do
          get :show, params: {id: question_id, course_id: other_course_id}
        end

        let(:other_course_id) { '00000001-3300-4444-9999-000000000022' }

        before do
          Stub.request(:course, :get, "/courses/#{other_course_id}")
            .to_return Stub.json(course_params.merge(id: other_course_id))
        end

        it 'does not find the question' do
          expect { action }.to raise_error Status::NotFound
        end
      end
    end

    context 'with pinboard.moderator permission' do
      let(:user) { stub_user id: user_id, language: 'en', permissions: ['course.content.access', 'pinboard.question.delete', 'pinboard.question.close'] }

      describe 'close' do
        let(:closed) { true }

        it 'closes thread' do
          post :close, params: {id: question_id, course_id:}
          expect(update_question_stub).to have_been_requested
        end
      end

      describe 'reopen' do
        let(:closed) { false }

        it 'reopens thread' do
          post :reopen, params: {id: question_id, course_id:}
          expect(update_question_stub).to have_been_requested
        end
      end
    end

    context 'as author' do
      describe 'edit' do
        it 'responds' do
          get :edit, params: {id: question_id, course_id:}
          expect(response).to have_http_status :ok
        end
      end

      describe 'delete' do
        it 'responds' do
          get :destroy, params: {id: question_id, course_id:}
          expect(response).to have_http_status :found
        end
      end
    end

    context 'as other user' do
      let(:author_id) { '00000000-0000-4444-9999-000000000002' }

      describe 'edit' do
        it 'responds' do
          get :edit, params: {id: question_id, course_id:}
          expect(response).to have_http_status :found
          expect(response).to redirect_to root_url
        end
      end
    end

    describe 'abuse_report' do
      let!(:abuse_report_stub) do
        Stub.request(
          :pinboard, :post, '/abuse_reports',
          body: hash_including(
            reportable_id: question_id,
            reportable_type: 'Question',
            user_id:,
            url: "http://test.host/courses/#{course_id}/question/#{question_id}"
          )
        ).to_return Stub.json({})
      end

      let(:action) do
        lambda do
          post :abuse_report, params: {
            id: question_id,
            course_id:,
          }
        end
      end

      before { action.call }

      it 'creates an abuse report' do
        expect(abuse_report_stub).to have_been_requested
      end

      it 'redirects' do
        expect(response).to redirect_to course_question_path
      end

      it 'adds a success message' do
        expect(flash[:success]).to include 'Your report was received successfully'
      end
    end

    describe 'block' do
      let!(:block_stub) do
        Stub.request(
          :pinboard, :put, "/questions/#{question_id}",
          body: hash_including(workflow_state: 'blocked', implicit_tags: [])
        ).to_return Stub.json(
          update_params.merge(abuse_report_state: 'blocked', implicit_tags: [])
        )
      end

      let(:action) do
        -> { post :block, params: {id: question_id, course_id:} }
      end

      before { action.call }

      it 'redirects to root' do
        expect(block_stub).not_to have_been_requested
        expect(response).to redirect_to root_path
      end

      context 'with pinboard.entity.block permission' do
        let(:permissions) { super() << 'pinboard.entity.block' }

        it 'updates the question' do
          expect(block_stub).to have_been_requested
        end
      end
    end

    describe 'unblock' do
      let!(:unblock_stub) do
        Stub.request(
          :pinboard, :put, "/questions/#{question_id}",
          body: hash_including(workflow_state: 'reviewed', implicit_tags: [])
        ).to_return Stub.json(update_params)
      end

      let(:action) do
        -> { post :unblock, params: {id: question_id, course_id:} }
      end

      before { action.call }

      it 'redirects to root' do
        expect(unblock_stub).not_to have_been_requested
        expect(response).to redirect_to root_path
      end

      context 'with pinboard.entity.block permission' do
        let(:permissions) { super() << 'pinboard.entity.block' }

        it 'updates the question' do
          expect(unblock_stub).to have_been_requested
        end
      end
    end
  end
end
