# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Result do
  subject(:result) { build(:'course_service/result', item:) }

  let!(:course) { create(:'course_service/course', start_date: nil, end_date: nil, records_released: true) }
  let!(:section) { create(:'course_service/section', course:, published: true) }
  let!(:item) { create(:'course_service/item', :with_max_points, section:, published: true) }

  it 'has a valid factory' do
    expect(result).to be_valid
  end

  context '(event publication)' do
    describe '(event publication) create result' do
      it 'enqueues a ResultCreateJob for a newly created result' do
        expect do
          result.save
        end.to have_enqueued_job(ResultCreateJob).with(
          hash_including(
            id: kind_of(String),
            user_id: result.user_id,
            item_id: item.id,
            points: result.dpoints / 10.0,
            course_id: section.course_id,
            section_id: section.id,
            content_type: item.content_type,
            content_id: item.content_id,
            exercise_type: item.exercise_type,
            submission_deadline: item.submission_deadline,
            submission_publishing_date: item.submission_publishing_date,
            max_points: item.max_dpoints / 10.0
          )
        )
      end
    end
  end

  context '(update section progress worker)' do
    it 'starts worker for a newly created result' do
      expect { result.save }.to have_enqueued_job(CourseService::LearningEvaluation::UpdateSectionProgressJob).exactly(:once)
    end

    it 'starts worker for an updated result' do
      result.save

      expect do
        result.dpoints += 10
        result.save
      end.to have_enqueued_job(CourseService::LearningEvaluation::UpdateSectionProgressJob).exactly(:once)
    end
  end
end
