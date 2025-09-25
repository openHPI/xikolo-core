# frozen_string_literal: true

require 'spec_helper'

describe Visit do
  subject(:visit) { build(:visit, item:) }

  let!(:course) { create(:course, start_date: nil, end_date: nil, records_released: true) }
  let!(:section) { create(:section, course:, published: true) }
  let!(:item) { create(:item, section:, published: true) }

  it 'has a valid factory' do
    expect(visit).to be_valid
  end

  describe '.latest_for' do
    subject(:latest_for) { Visit.latest_for(user: visit.user_id, items: [item, another_item]) }

    let(:visit) { create(:visit, item:, updated_at: Time.current) }
    let(:another_item) { create(:item, section:, published: true) }

    before do
      # The same user visits another item
      create(:visit, user_id: visit.user_id, item: another_item, updated_at: 2.hours.ago)

      # Another user visits the same item
      create(:visit, item:, updated_at: 1.hour.ago)
    end

    it 'returns the item with the latest visit' do
      expect(latest_for.take).to eq(visit)
    end
  end

  context '(event publication)' do
    describe 'create visit' do
      it 'publishes an event for a newly created visit' do
        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq \
            id: visit.id,
            item_id: item.id,
            user_id: visit.user_id,
            created_at: visit.created_at.iso8601,
            updated_at: visit.updated_at.iso8601,
            course_id: item.section.course_id,
            section_id: item.section.id,
            content_type: item.content_type,
            content_id: item.content_id,
            exercise_type: item.exercise_type,
            submission_deadline: item.submission_deadline,
            submission_publishing_date: item.submission_publishing_date,
            max_points: (item.max_dpoints / 10.0 if item.max_dpoints)
          expect(opts).to eq to: 'xikolo.course.visit.create'
        end
        visit.save
      end
    end

    describe 'touch visit' do
      let!(:visit) { create(:visit, item:) }

      it 'publishes an event for the updated visit' do
        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to include \
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
          expect(opts).to eq to: 'xikolo.course.visit.create'
        end
        visit.touch
      end
    end
  end

  context '(enrollment completion worker)' do
    it 'starts worker for a newly created visit' do
      expect { visit.save }.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
    end
  end

  context '(update section progress worker)' do
    it 'starts worker for a newly created visit' do
      expect { visit.save }.to change(LearningEvaluation::UpdateSectionProgressWorker.jobs, :size).from(0).to(1)
    end
  end
end
