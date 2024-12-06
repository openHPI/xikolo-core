# frozen_string_literal: true

require 'spec_helper'

describe Result do
  subject(:result) { build(:result, item:) }

  let!(:course) { create(:course, start_date: nil, end_date: nil, records_released: true) }
  let!(:section) { create(:section, course:, published: true) }
  let!(:item) { create(:item, :with_max_points, section:, published: true) }

  it 'has a valid factory' do
    expect(result).to be_valid
  end

  context '(event publication)' do
    describe 'create result' do
      it 'publishes an event for a newly created result' do
        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq \
            id: result.id,
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
            max_points: item.max_dpoints / 10.0,
            created_at: result.created_at,
            updated_at: result.updated_at
          expect(opts).to eq to: 'xikolo.course.result.create'
        end

        result.save
      end
    end

    describe 'update result' do
      it 'publishes an event for an updated result' do
        result.save

        result.dpoints += 10

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq \
            id: result.id,
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
            max_points: item.max_dpoints / 10.0,
            created_at: result.created_at,
            updated_at: result.updated_at
          expect(opts).to eq to: 'xikolo.course.result.update'
        end

        result.save
      end
    end
  end

  context '(enrollment completion worker)' do
    it 'starts worker for a newly created result' do
      expect { result.save }.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
    end

    it 'starts worker for an updated result' do
      result.save
      Sidekiq::Worker.clear_all

      expect do
        result.dpoints += 10
        result.save
      end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
    end
  end

  context '(update section progress worker)' do
    it 'starts worker for a newly created result' do
      expect { result.save }.to change(LearningEvaluation::UpdateSectionProgressWorker.jobs, :size).from(0).to(1)
    end

    it 'starts worker for an updated result' do
      result.save
      Sidekiq::Worker.clear_all

      expect do
        result.dpoints += 10
        result.save
      end.to change(LearningEvaluation::UpdateSectionProgressWorker.jobs, :size).from(0).to(1)
    end
  end
end
