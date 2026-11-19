# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Course::Destroy, type: :operation do
  subject(:action) { described_class.call(course) }

  let(:code) { 'the-course-code' }
  let(:course) do
    create(:'course_service/course',
      course_code: code,
      skip_account_groups: true)
  end

  let!(:context_stub) do
    Stub.request(
      :account,
      :delete,
      "/contexts/#{course.context_id}"
    ).to_return(status: 200)
  end

  %w[students admins moderators teachers].each do |name|
    let!(:"group_#{name}_stub") do
      Stub.request(
        :account,
        :delete,
        "/groups/course.#{course.course_code}.#{name}"
      ).to_return(status: 200)
    end
  end

  it 'soft-deletes the course' do
    expect { action }.to change(course, :deleted).from(false).to(true)
  end

  it 'does not delete the course' do
    expect { action }.not_to change(CourseService::Course, :count)
  end

  it 'records when the course was flagged for deletion' do
    Timecop.freeze do
      action
      expect(course.reload.deleted_at).to be_within(1.second).of(Time.current)
    end
  end

  it 'deletes the course special groups' do
    action
    expect(group_students_stub).to have_been_requested
    expect(group_admins_stub).to have_been_requested
    expect(group_moderators_stub).to have_been_requested
    expect(group_teachers_stub).to have_been_requested
  end

  it 'deletes the course context' do
    action
    expect(context_stub).to have_been_requested
  end

  context 'course_code obfuscation' do
    let!(:now) { Time.current }

    it 'obfuscates the course code' do
      # Freeze the time when calling the action so that we can compare
      # the calculated course code hash that uses the current time.
      Timecop.freeze { action }

      expect(course.reload.course_code).to eq("#{code}-deleted-#{Digest::MD5.hexdigest(now.to_s)}")
    end
  end

  context 'with failing account service' do
    let(:group_admins_stub) do
      Stub.request(
        :account,
        :delete,
        "/groups/course.#{course.course_code}.admins"
      ).to_return(status: 500)
    end

    it 'does not raise an exception' do
      expect { action }.not_to raise_error
    end
  end
end
