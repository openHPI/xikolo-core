# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::LearningEvaluation::PersistForCourseJob, type: :job do
  subject(:perform) do
    perform_enqueued_jobs do
      described_class.perform_later(course.id)
    end
  end

  let(:course) { create(:'course_service/course') }
  let(:another_course) { create(:'course_service/course') }
  let(:section11) { create(:'course_service/section', course:) }
  let(:section12) { create(:'course_service/section', course:) }
  let(:section21) { create(:'course_service/section', course: another_course) }
  let(:section22) { create(:'course_service/section', course: another_course) }

  before do
    create(:'course_service/item', section: section11)
    create(:'course_service/item', section: section12)

    create(:'course_service/item', section: section21)
    section22
  end

  it 'with no enrollments for the courses, it generates no progresses' do
    perform
    expect(CourseService::CourseProgress.count).to be_zero
    expect(CourseService::SectionProgress.count).to be_zero
  end

  context 'with enrollments for the courses' do
    before do
      3.times { create(:'course_service/enrollment', course_id: course.id) }
      2.times { create(:'course_service/enrollment', course_id: another_course.id) }
    end

    it 'generates all progresses' do
      perform
      expect(CourseService::CourseProgress.where(course_id: course.id).count).to eq 3
      expect(CourseService::CourseProgress.where(course_id: another_course.id).count).to be_zero

      expect(CourseService::SectionProgress.where(section_id: section11.id).count).to eq 3
      expect(CourseService::SectionProgress.where(section_id: section12.id).count).to eq 3
      expect(CourseService::SectionProgress.where(section_id: section21.id).count).to be_zero
      expect(CourseService::SectionProgress.where(section_id: section22.id).count).to be_zero
    end

    it 'does not call the progress calculation operations multiple times' do
      # A course progress per enrollment (user), 3 for this course.
      expect(CourseService::CourseProgress::Calculate).to receive(:call).exactly(3).times
      # A section progress for every user in both sections.
      expect(CourseService::SectionProgress::Calculate).to receive(:call).exactly(6).times
      perform
    end
  end
end
