# frozen_string_literal: true

require 'spec_helper'

describe Collabspace::Ajax::CalendarEventsController, type: :controller do
  let(:user_id) { generate(:user_id) }
  let(:member_id) { generate(:user_id) }
  let(:collab_space_id) { SecureRandom.uuid }
  let(:course) { build(:'course:course', context_id: request_context_id) }
  let(:request_context_id) { generate(:context_id) }

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

  describe '#index' do
    subject { get :index, params: {course_id: course['id'], learning_room_id: collab_space_id}, xhr: true }

    before do
      Stub.request(
        :collabspace, :get, '/calendar_events',
        query: {collab_space_id:}
      ).to_return Stub.json([
        {
          id: SecureRandom.uuid,
          start_time: 2.days.ago.iso8601,
          end_time: 2.days.ago.iso8601,
        },
      ])
    end

    context 'anonymous' do
      it { is_expected.to have_http_status :forbidden }
    end

    context 'without membership' do
      before { stub_user id: user_id, permissions: ['course.content.access.available'] }

      it { is_expected.to have_http_status :forbidden }
    end

    context 'with membership' do
      before { stub_user id: member_id, permissions: ['course.content.access.available'] }

      it { is_expected.to have_http_status :ok }
    end
  end
end
