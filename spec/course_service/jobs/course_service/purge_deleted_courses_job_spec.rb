# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::PurgeDeletedCoursesJob, type: :job do
  let!(:old_deleted_course) do
    create(:'course_service/course', skip_account_groups: true, deleted: true, deleted_at: 7.months.ago)
  end

  let!(:recent_deleted_course) do
    create(:'course_service/course', skip_account_groups: true, deleted: true, deleted_at: 5.months.ago)
  end

  let!(:not_deleted_course) do
    create(:'course_service/course', skip_account_groups: true)
  end

  it 'purges only deleted courses that are old enough' do
    expect(CourseService::Course::Purge).to receive(:call).with(old_deleted_course).once
    expect(CourseService::Course::Purge).not_to receive(:call).with(recent_deleted_course)
    expect(CourseService::Course::Purge).not_to receive(:call).with(not_deleted_course)

    described_class.perform_now
  end
end
