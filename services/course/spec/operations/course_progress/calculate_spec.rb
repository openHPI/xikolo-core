# frozen_string_literal: true

require 'spec_helper'

describe CourseProgress::Calculate, type: :operation do
  subject(:calculate) { described_class.call(section.course_id, user_id) }

  let(:section) { create(:'course_service/section') }
  let(:item) { create(:'course_service/item', :homework, :with_max_points, section:) }
  let(:user_id) { generate(:user_id) }

  before do
    item # Relevant for max_dpoints / max_visits calculation.
    create(:'course_service/section_progress', section:, user_id:, visits: 1, main_dpoints: 10, main_exercises: 1)
  end

  it 'creates a course progress and triggers the calculation' do
    expect { calculate }.to change(CourseProgress, :count).from(0).to(1)
    expect(CourseProgress.first).to have_attributes(
      course_id: section.course_id,
      user_id:,
      visits: 1,
      main_dpoints: 10,
      main_exercises: 1,
      max_dpoints: 10,
      max_visits: 1
    )
  end

  context 'with existing course progress for the user' do
    before do
      create(:'course_service/course_progress', course: section.course, user_id:, visits: 2)
    end

    it 'updates the existing course progress' do
      expect(CourseProgress.first).to have_attributes(
        course_id: section.course_id,
        user_id:,
        visits: 2,
        main_dpoints: 0,
        main_exercises: 0,
        max_dpoints: 0,
        max_visits: 0
      )
      expect { calculate }.not_to change(CourseProgress, :count).from(1)
      expect(CourseProgress.first).to have_attributes(
        course_id: section.course_id,
        user_id:,
        visits: 1,
        main_dpoints: 10,
        main_exercises: 1,
        max_dpoints: 10,
        max_visits: 1
      )
    end
  end
end
