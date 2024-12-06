# frozen_string_literal: true

require 'spec_helper'

describe Collabspace::CalendarEventsController, type: :controller do
  let(:user_id) { generate(:user_id) }
  let(:member_id) { generate(:user_id) }
  let(:collab_space_id) { SecureRandom.uuid }
  let(:course) { build(:'course:course', context_id: request_context_id) }
  let(:event_id) { SecureRandom.uuid }
  let(:request_context_id) { generate(:context_id) }
  let(:params) do
    {
      'title' => 'Test Event',
      'description' => 'Test Description',
      'color' => 'unavailable',
    }
  end

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}'
    )

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course['id']}"
    ).to_return Stub.json(course)

    Stub.service(
      :collabspace,
      memberships_url: '/memberships',
      calendar_events_url: '/calendar_events',
      calendar_event_url: '/calendar_events/{id}'
    )
    Stub.request(
      :collabspace, :get, '/memberships',
      query: {user_id: member_id, collab_space_id:}
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
    ])
    Stub.request(
      :collabspace, :get, '/memberships',
      query: {user_id:, collab_space_id:}
    ).to_return Stub.json([])
  end

  describe '#create' do
    subject { post :create, params: {calendar_event: params, course_id: course['id'], learning_room_id: collab_space_id}, xhr: true }

    before do
      Stub.request(
        :collabspace, :post, '/calendar_events'
      ).to_return Stub.json(
        params.merge('id' => event_id)
      )
    end

    context 'with membership' do
      before do
        stub_user id: member_id, permissions: ['course.content.access.available'], features: {'collabspace_calendar' => 'true'}
      end

      it { is_expected.to have_http_status :ok }
    end
  end

  describe '#update' do
    subject { put :update, params: {calendar_event: params, course_id: course['id'], learning_room_id: collab_space_id, id: event_id}, xhr: true }

    let(:owner_id) { SecureRandom.uuid }

    before do
      Stub.request(
        :collabspace, :patch, "/calendar_events/#{event_id}"
      ).to_return(status: 204, body: '', headers: {})

      Stub.request(
        :collabspace, :get, "/calendar_events/#{event_id}"
      ).to_return Stub.json({
        id: SecureRandom.uuid,
        user_id: owner_id,
      })

      Stub.request(
        :collabspace, :get, '/memberships',
        query: {user_id: owner_id, collab_space_id:}
      ).to_return Stub.json([
        {id: SecureRandom.uuid},
      ])
    end

    context 'with membership but not owner or privileged' do
      before do
        stub_user id: member_id, permissions: ['course.content.access.available'], features: {'collabspace_calendar' => 'true'}
      end

      it { is_expected.to have_http_status :found }
    end

    context 'as owner' do
      before do
        stub_user id: owner_id, permissions: ['course.content.access.available'], features: {'collabspace_calendar' => 'true'}
      end

      it { is_expected.to have_http_status :ok }
    end
  end

  describe '#delete' do
    subject { delete :destroy, params: {course_id: course['id'], learning_room_id: collab_space_id, id: event_id}, xhr: true }

    let(:owner_id) { generate(:user_id) }

    before do
      Stub.request(
        :collabspace, :delete, "/calendar_events/#{event_id}"
      ).to_return(status: 204, body: '', headers: {})

      Stub.request(
        :collabspace, :get, "/calendar_events/#{event_id}"
      ).to_return Stub.json({
        id: SecureRandom.uuid,
        user_id: owner_id,
      })

      Stub.request(
        :collabspace, :get, '/memberships',
        query: {user_id: owner_id, collab_space_id:}
      ).to_return Stub.json([
        {id: SecureRandom.uuid},
      ])
    end

    context 'with membership but not owner or privileged' do
      before do
        stub_user id: member_id, permissions: ['course.content.access.available'], features: {'collabspace_calendar' => 'true'}
      end

      it { is_expected.to have_http_status :found }
    end

    context 'as owner' do
      before do
        stub_user id: owner_id, permissions: ['course.content.access.available'], features: {'collabspace_calendar' => 'true'}
      end

      it { is_expected.to have_http_status :ok }
    end
  end
end
