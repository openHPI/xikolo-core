# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Course::Purge, type: :operation do
  subject(:action) { described_class.call(course) }

  let(:course) do
    create(:'course_service/course', :with_content_tree, :with_sections, skip_account_groups: true,
      deleted: true, deleted_at: 7.months.ago)
  end
  let(:section) { course.sections.first }
  let(:user) { create(:'account_service/user') }

  before do
    create(:'course_service/enrollment', course:)
    create(:'course_service/course_progress', course:, user_id: user.id)
    create(:'course_service/course_subscription', course_id: course.id, user_id: user.id)
    create(:'course_service/next_date', course:, user_id: user.id)
    create(:'course_service/item', section: section, title: 'Peer assessment',
      content_type: 'peer_assessment', content_id: SecureRandom.uuid)
    create(:'course_service/item', section:, title: 'Video', content_type: 'video')
  end

  it 'removes the course and its dependent records' do
    expect { action }
      .to change(CourseService::Enrollment, :count).by(-1)
      .and change(CourseService::CourseProgress, :count).by(-1)
      .and change(PinboardService::CourseSubscription, :count).by(-1)
      .and change(CourseService::NextDate, :count).by(-1)
      .and change(CourseService::Item, :count).by(-2)
      .and change(CourseService::Section, :count).by(-3)
      .and change(CourseService::Course, :count).by(-1)
  end

  it 'can handle peer assessment items' do
    expect { action }.not_to raise_error
  end

  it 'destroys the course' do
    action

    expect(CourseService::Course.exists?(course.id)).to be false
  end
end
