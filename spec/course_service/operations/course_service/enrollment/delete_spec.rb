# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Enrollment::Delete, type: :operation do
  subject(:operation) { handler.call enrollment }

  let(:enrollment) { create(:'course_service/enrollment') }
  let(:handler) { described_class }
  let(:membership_stub) do
    Stub.request(
      :account, :delete, '/memberships',
      query: {
        user: enrollment.user_id,
        group: "course.#{enrollment.course.course_code}.students",
      }
    )
  end

  before do
    membership_stub
  end

  it 'deletes the membership' do
    operation
    expect(membership_stub).to have_been_requested
  end

  it 'archives enrollment' do
    expect { operation }.to change { enrollment.reload.deleted }.from(false).to(true)
  end

  context 'with error destroying membership' do
    let(:membership_stub) do
      Stub.request(
        :account, :delete, '/memberships',
        query: {
          user: enrollment.user_id,
          group: "course.#{enrollment.course.course_code}.students",
        }
      ).to_return Stub.response(status: 403)
    end

    it 'does not archive the enrollment' do
      expect { operation }.not_to change { enrollment.reload.deleted }.from(false)

      expect(operation.errors.size).to eq 1
      expect(operation.errors[:base]).to eq ['error deleting membership']
    end
  end
end
