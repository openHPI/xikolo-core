# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Courses::Items do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:user_visit) { nil }
  let(:user_id) { SecureRandom.uuid }
  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:item_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:context_id) { SecureRandom.uuid }
  let(:permissions) { ['course.content.access.available'] }
  let(:features) { {} }

  let(:plain_item) do
    {
      id: item_id,
      title: 'Item title',
      position: 1,
      submission_deadline: 4.days.from_now.iso8601,
      effective_start_date: 2.days.ago.iso8601,
      effective_end_date: 4.days.from_now.iso8601,
      content_type: 'quiz',
      exercise_type: 'main',
      icon_type: nil,
      proctored: false,
      course_id:,
      time_effort: 100,
    }
  end

  let(:item) do
    plain_item.merge(user_visit:)
  end

  let(:course) do
    {
      id: course_id,
      context_id:,
    }
  end

  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_AUTHORIZATION' => "Legacy-Token #{stub_session_id}",
    }
  end

  before do
    Stub.service(:account, build(:'account:root'))
    api_stub_user(id: user_id, permissions:, features:, context_id:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course[:id]}"
    ).to_return Stub.json(course)
    Stub.request(
      :course, :get, "/items/#{plain_item[:id]}"
    ).to_return Stub.json(plain_item)
    Stub.request(
      :course, :get, "/items/#{item[:id]}",
      query: {embed: 'user_visit', user_id:}
    ).to_return Stub.json(item)
  end

  describe 'GET course-items/:id' do
    subject(:response) { get "/v2/course-items/#{item[:id]}", nil, env_hash }

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    describe '(json)' do
      subject(:json) { JSON.parse response.body }

      it { is_expected.to be_a Hash }

      it { is_expected.to have_type 'course-items' }
      it { is_expected.to have_id item[:id] }

      it { is_expected.to have_attribute 'title' }
      it { is_expected.to have_attribute 'position' }
      it { is_expected.to have_attribute 'deadline' }
      it { is_expected.to have_attribute 'content_type' }
      it { is_expected.to have_attribute 'icon' }
      it { is_expected.to have_attribute 'exercise_type' }
      it { is_expected.to have_attribute 'max_points' }
      it { is_expected.to have_attribute 'proctored' }
      it { is_expected.to have_attribute 'accessible' }
      it { is_expected.to have_attribute 'visited' }
      it { is_expected.to have_attribute 'time_effort' }

      describe '[time_effort]' do
        subject { json.dig('data', 'attributes', 'time_effort') }

        it { is_expected.to eq 0 }

        context 'when the feature is enabled' do
          let(:features) { {time_effort: true} }

          it { is_expected.to eq 100 }
        end
      end

      context 'when there is a visit for the current user' do
        let(:user_visit) { {} }

        describe '[visited]' do
          subject { json.dig('data', 'attributes', 'visited') }

          it { is_expected.to be true }
        end
      end
    end

    context 'without an enrollment' do
      let(:permissions) { [] }

      it 'responds with 403 Forbidden' do
        expect(response.status).to eq 403
      end
    end

    context 'as an administrator' do
      let(:permissions) { ['course.content.access'] }

      it 'responds with 200 Ok' do
        expect(response.status).to eq 200
      end
    end
  end

  describe 'PATCH course-items/:id' do
    subject(:response) { patch "v2/course-items/#{item[:id]}", patch_data.to_json, env_hash }

    let(:patch_data) do
      {
        data: {
          type: 'course-items',
          id: item[:id],
          attributes: patch_attributes,
        },
      }
    end

    let!(:create_user_visit) do
      Stub.request(
        :course, :post, "/items/#{item[:id]}/users/#{user_id}/visit"
      ).to_return Stub.json({})
    end

    context 'when marking the item as visited' do
      let(:patch_attributes) { {visited: true} }

      it 'creates a new visit object for the user' do
        response
        expect(create_user_visit).to have_been_requested
      end

      it 'responds with 200 Ok' do
        expect(response.status).to eq 200
      end

      describe '(json)' do
        subject { JSON.parse response.body }

        it { is_expected.to be_a Hash }

        it { is_expected.to have_type 'course-items' }
        it { is_expected.to have_id item[:id] }
      end

      context 'without an enrollment' do
        let(:permissions) { [] }

        it 'responds with 403 Forbidden' do
          expect(response.status).to eq 403
        end
      end

      context 'as an administrator' do
        let(:permissions) { ['course.content.access'] }

        it 'responds with 200 Ok' do
          expect(response.status).to eq 200
        end
      end
    end
  end
end
