# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Visit do
  subject(:visit) { build(:'course_service/visit', item:) }

  let!(:course) { create(:'course_service/course', start_date: nil, end_date: nil, records_released: true) }
  let!(:section) { create(:'course_service/section', course:, published: true) }
  let!(:item) { create(:'course_service/item', section:, published: true) }

  it 'has a valid factory' do
    expect(visit).to be_valid
  end

  describe '.latest_for' do
    subject(:latest_for) { CourseService::Visit.latest_for(user: visit.user_id, items: [item, another_item]) }

    let(:visit) { create(:'course_service/visit', item:, updated_at: Time.current) }
    let(:another_item) { create(:'course_service/item', section:, published: true) }

    before do
      # The same user visits another item
      create(:'course_service/visit', user_id: visit.user_id, item: another_item, updated_at: 2.hours.ago)

      # Another user visits the same item
      create(:'course_service/visit', item:, updated_at: 1.hour.ago)
    end

    it 'returns the item with the latest visit' do
      expect(latest_for.take).to eq(visit)
    end
  end

  context '(event publication)' do
    describe 'create visit' do
      it 'enqueues a VisitCreateJob for a newly created visit' do
        expect do
          visit.save
        end.to have_enqueued_job(VisitCreateJob).with(
          id: visit.id,
          item_id: item.id,
          user_id: visit.user_id,
          created_at: kind_of(String),
          updated_at: kind_of(String),
          course_id: item.section.course_id,
          section_id: item.section.id,
          content_type: item.content_type,
          content_id: item.content_id,
          exercise_type: item.exercise_type,
          submission_deadline: item.submission_deadline,
          submission_publishing_date: item.submission_publishing_date,
          max_points: (item.max_dpoints / 10.0 if item.max_dpoints)
        )
      end
    end

    describe 'touch visit' do
      let!(:visit) { create(:'course_service/visit', item:) }

      it 'enqueues a VisitCreateJob for the updated visit' do
        expect do
          visit.touch
        end.to have_enqueued_job(VisitCreateJob).with(
          hash_including(
            id: visit.id,
            item_id: item.id,
            user_id: visit.user_id,
            created_at: visit.created_at.iso8601,
            course_id: item.section.course_id,
            section_id: item.section.id,
            content_type: item.content_type,
            content_id: item.content_id,
            exercise_type: item.exercise_type,
            submission_deadline: item.submission_deadline,
            submission_publishing_date: item.submission_publishing_date,
            max_points: (item.max_dpoints / 10.0 if item.max_dpoints)
          )
        )
      end
    end
  end

  context '(update section progress worker)' do
    it 'starts worker for a newly created visit' do
      expect { visit.save }.to have_enqueued_job(CourseService::LearningEvaluation::UpdateSectionProgressJob).exactly(:once)
    end
  end
end
