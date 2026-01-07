# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Enrollment, '#with_evaluation', type: :model do
  subject(:evaluation) { CourseService::Enrollment.all.with_evaluation }

  let!(:enrollment1) { create(:'course_service/enrollment') }
  let!(:enrollment2) { create(:'course_service/enrollment') }
  let!(:enrollment3) { create(:'course_service/enrollment') }

  context 'without any course progresses' do
    it { expect(evaluation.size).to eq 3 }

    it 'includes empty results' do
      expect(evaluation).to all have_attributes(
        visits_visited: 0,
        visits_total: 0,
        visits_percentage: 0.0,
        user_dpoints: 0,
        maximal_dpoints: 0,
        points_percentage: 0.0
      )
    end
  end

  context 'with course progresses' do
    before do
      create(:'course_service/course_progress', course: enrollment1.course, user_id: enrollment1.user_id,
        visits: 10,
        main_dpoints: 50,
        bonus_dpoints: 20,
        max_dpoints: 150,
        max_visits: 30,
        points_percentage_fpoints: 46_66,
        visits_percentage_fpoints: 33_33)

      create(:'course_service/course_progress', course: enrollment2.course, user_id: enrollment2.user_id,
        visits: 7,
        main_dpoints: 3,
        bonus_dpoints: 0,
        max_dpoints: 10,
        max_visits: 35,
        points_percentage_fpoints: 30_00,
        visits_percentage_fpoints: 20_00)

      create(:'course_service/course_progress', course: enrollment3.course, user_id: enrollment3.user_id,
        visits: 50,
        main_dpoints: 50,
        bonus_dpoints: 10,
        max_dpoints: 50,
        max_visits: 50,
        points_percentage_fpoints: 100_00,
        visits_percentage_fpoints: 100_00)
    end

    it { expect(evaluation.size).to eq 3 }

    it 'includes evaluation for each enrollment' do
      expect(evaluation.find_by(course_id: enrollment1.course_id, user_id: enrollment1.user_id))
        .to have_attributes(
          visits_visited: 10,
          visits_total: 30,
          visits_percentage: 33.33,
          user_dpoints: 70,
          maximal_dpoints: 150,
          points_percentage: 46.66
        )

      expect(evaluation.find_by(course_id: enrollment2.course_id, user_id: enrollment2.user_id))
        .to have_attributes(
          visits_visited: 7,
          visits_total: 35,
          visits_percentage: 20.0,
          user_dpoints: 3,
          maximal_dpoints: 10,
          points_percentage: 30.0
        )

      expect(evaluation.find_by(course_id: enrollment3.course_id, user_id: enrollment3.user_id))
        .to have_attributes(
          visits_visited: 50,
          visits_total: 50,
          visits_percentage: 100.0,
          user_dpoints: 50,
          maximal_dpoints: 50,
          points_percentage: 100.0
        )
    end
  end
end
