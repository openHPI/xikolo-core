# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearningEvaluation::PersistForCourseWorker, type: :worker do
  subject(:perform) do
    Sidekiq::Testing.inline! do
      described_class.perform_async
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

  describe 'for all courses' do
    it 'with no enrollments for the courses, it generates no progresses' do
      perform
      expect(CourseProgress.count).to be_zero
      expect(SectionProgress.count).to be_zero
    end

    context 'with enrollments for the courses' do
      before do
        3.times { create(:'course_service/enrollment', course_id: course.id, user_id: generate(:user_id)) }
        2.times { create(:'course_service/enrollment', course_id: another_course.id, user_id: generate(:user_id)) }
      end

      it 'generates all progresses' do
        perform
        expect(CourseProgress.where(course_id: course.id).count).to eq 3
        expect(CourseProgress.where(course_id: another_course.id).count).to eq 2

        expect(SectionProgress.where(section_id: section11.id).count).to eq 3
        expect(SectionProgress.where(section_id: section12.id).count).to eq 3
        expect(SectionProgress.where(section_id: section21.id).count).to eq 2
        expect(SectionProgress.where(section_id: section22.id).count).to be_zero
      end

      it 'does not call the progress calculation operations multiple times' do
        # A course progress per enrollment (user), 3 and 2 for the courses.
        expect(CourseProgress::Calculate).to receive(:call).exactly(5).times
        # A section progress for every user (3) in both sections for the first course.
        # A section progress for every user (2) in the first section for the second course.
        expect(SectionProgress::Calculate).to receive(:call).exactly(8).times
        perform
      end
    end
  end

  describe 'for a specific course' do
    subject(:perform) do
      Sidekiq::Testing.inline! do
        described_class.perform_async(course.id)
      end
    end

    it 'with no enrollments for the courses, it generates no progresses' do
      perform
      expect(CourseProgress.count).to be_zero
      expect(SectionProgress.count).to be_zero
    end

    context 'with enrollments for the courses' do
      before do
        3.times { create(:'course_service/enrollment', course_id: course.id, user_id: generate(:user_id)) }
        2.times { create(:'course_service/enrollment', course_id: another_course.id, user_id: generate(:user_id)) }
      end

      it 'generates all progresses' do
        perform
        expect(CourseProgress.where(course_id: course.id).count).to eq 3
        expect(CourseProgress.where(course_id: another_course.id).count).to be_zero

        expect(SectionProgress.where(section_id: section11.id).count).to eq 3
        expect(SectionProgress.where(section_id: section12.id).count).to eq 3
        expect(SectionProgress.where(section_id: section21.id).count).to be_zero
        expect(SectionProgress.where(section_id: section22.id).count).to be_zero
      end

      it 'does not call the progress calculation operations multiple times' do
        # A course progress per enrollment (user), 3 for this course.
        expect(CourseProgress::Calculate).to receive(:call).exactly(3).times
        # A section progress for every user in both sections.
        expect(SectionProgress::Calculate).to receive(:call).exactly(6).times
        perform
      end
    end
  end
end
