# frozen_string_literal: true

require 'spec_helper'

describe Course::Ajax::TopicsController, type: :controller do
  let(:user_id) { generate(:user_id) }
  let(:course) { build(:'course:course', context_id: request_context_id) }
  let(:request_context_id) { generate(:context_id) }

  before do
    Stub.service(:account, build(:'account:root'))

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course['id']}"
    ).to_return Stub.json(course)

    Stub.service(:pinboard, build(:'pinboard:root'))
  end

  describe '#create' do
    subject(:create_topic) do
      post :create,
        params: {course_id: course['id'], item_id:, topic: topic_params},
        xhr: true
    end

    let(:topic_params) do
      {title: 'New topic', text: 'What is this about?', video_timestamp: '0'}
    end
    let(:item_id) { generate(:item_id) }
    let(:topic_id) { SecureRandom.uuid }
    let!(:create_stub) do
      Stub.request(
        :pinboard, :post, '/topics',
        body: {
          title: topic_params[:title],
          first_post: {text: topic_params[:text]},
          meta: {video_timestamp: topic_params[:video_timestamp]},
          author_id: user_id,
          course_id: course['id'],
          item_id:,
        }
      ).to_return Stub.json({
        id: topic_id,
        title: topic_params[:title],
        abstract: topic_params[:text],
        tags: [],
        closed: false,
        num_replies: 0,
        meta: {video_timestamp: 0},
        url: "/topics/#{topic_id}",
      })
    end

    context 'for anonymous user' do
      it { is_expected.to have_http_status(:forbidden) }
    end

    context 'for logged-in user' do
      let(:permissions) { %w[course.content.access.available] }

      before { stub_user id: user_id, permissions: }

      it { is_expected.to have_http_status(:ok) }

      it 'creates the topic' do
        create_topic
        expect(create_stub).to have_been_requested
      end

      context 'with invalid topic params' do
        let(:topic_params) { {title: 'New topic', video_timestamp: '0'} }
        let(:json) { response.parsed_body }

        it 'fails with proper error message' do
          create_topic
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json).to eq('errors' => {'text' => ["The text can't be blank."]})
        end
      end

      context 'without permission' do
        let(:permissions) { [] }

        it { is_expected.to have_http_status(:forbidden) }
      end
    end
  end
end
