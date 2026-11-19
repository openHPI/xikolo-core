# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Enrollment::Create, type: :operation do
  subject(:operation) { described_class.call user_id, course, params }

  let(:user_id) { create(:'account_service/user').id }
  let(:course) { create(:'course_service/course') }
  let(:params) { {} }

  let(:membership_stub) do
    Stub.request(
      :account, :post, '/memberships',
      body: {
        group: "course.#{course.course_code}.students",
        user: user_id,
      }
    )
  end

  before do
    membership_stub
  end

  it 'creates an enrollment' do
    expect(operation).to be_valid
    expect(operation).to be_persisted
  end

  it 'creates a membership' do
    operation
    expect(membership_stub).to have_been_requested
  end

  it 'enqueues a welcome email job' do
    expect do
      operation
    end.to have_enqueued_job(
      NotificationService::SendCourseWelcomeEmailJob
    ).with(
        hash_including(user_id: user_id, course_id: course.id)
      )
  end

  context 'with error when creating the membership' do
    let(:membership_stub) do
      Stub.request(
        :account, :post, '/memberships',
        body: {
          group: "course.#{course.course_code}.students",
          user: user_id,
        }
      ).to_return Stub.response(status: 422)
    end

    it 'does not create the enrollment' do
      expect { operation }.not_to change(CourseService::Enrollment, :count).from(0)

      expect(operation.errors.size).to eq 1
      expect(operation.errors[:base]).to eq ['membership_creation_failed']
    end

    it 'does not enqueue a welcome email job' do
      expect do
        operation
      end.not_to have_enqueued_job(NotificationService::SendCourseWelcomeEmailJob)
    end
  end

  context 'with group restrictions' do
    let(:group) { 'group.name' }
    let(:course) { create(:'course_service/course', groups: [group]) }

    context 'with user in group' do
      before do
        Stub.request(:account, :get, '/groups', query: {
          user: user_id, per_page: 1000
        }).to_return Stub.json([{name: group}])
      end

      it 'creates enrollment' do
        expect { operation }.to change(CourseService::Enrollment, :count).from(0).to(1)

        CourseService::Enrollment.last.tap do |enrollment|
          expect(enrollment.course_id).to eq course.id
          expect(enrollment.user_id).to eq user_id
        end
      end
    end

    context 'without user in group' do
      before do
        Stub.request(:account, :get, '/groups', query: {
          user: user_id, per_page: 1000
        }).to_return Stub.json([{name: 'other.group'}])
      end

      it 'does not create enrollment' do
        expect { operation }.not_to change(CourseService::Enrollment, :count).from(0)
      end

      it 'fails with course restriction' do
        expect(operation.errors[:base]).to eq ['access_restricted']
      end
    end

    context 'with response error' do
      before do
        Stub.request(:account, :get, '/groups', query: {
          user: user_id, per_page: 1000
        }).to_return Stub.response(status: 500)
      end

      it 'does not create enrollment' do
        expect { operation }.not_to change(CourseService::Enrollment, :count).from(0)
      end

      it 'fails with course restriction' do
        expect(operation.errors[:base]).to eq ['access_restricted']
      end
    end
  end
end
