# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::NextDate::CourseStartSyncJob, type: :job do
  let(:course) do
    create(:'course_service/course',
      display_start_date:,
      published:,
      start_date:)
  end
  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(course.id), 'course_start').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'user_id' => '00000000-0000-0000-0000-000000000000',
      'type' => 'course_start',
      'course_id' => course.id,
      'resource_type' => 'course',
      'resource_id' => course.id,
      'title' => course.title,
      'section_pos' => 0,
      'item_pos' => nil,
    }
  end

  def perform
    course
    perform_enqueued_jobs do
      described_class.perform_later(course.id)
    end
  end

  it 'does not fail for unknown courses' do
    perform_enqueued_jobs do
      described_class.perform_later(SecureRandom.uuid)
    end

    expect(CourseService::NextDate.count).to eq(0)
  end

  context 'for a published course' do
    let(:published) { true }

    context 'with previously created date' do
      let(:start_date) { nil }
      let(:display_start_date) { 1.day.from_now }

      it 'updates an previous date' do
        CourseService::NextDate.create! attrs.merge(date: 2.days.from_now)

        expect { perform }.not_to change(CourseService::NextDate, :count)
        date = CourseService::NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(display_start_date)
      end
    end

    context 'with display start date' do
      let(:start_date) { 1.day.ago }
      let(:display_start_date) { 1.day.from_now }

      it 'creates an next date' do
        perform

        expect(CourseService::NextDate.count).to eq 1
        date = CourseService::NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(display_start_date)
      end
    end

    context 'without display but start date' do
      let(:start_date) { 1.day.from_now }
      let(:display_start_date) { nil }

      it 'creates an next date' do
        perform

        expect(CourseService::NextDate.count).to eq 1
        date = CourseService::NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(start_date)
      end
    end

    context 'without display and start date' do
      let(:start_date) { nil }
      let(:display_start_date) { nil }

      it 'creates an next date' do
        perform

        expect(CourseService::NextDate.count).to eq 0
      end
    end
  end

  context 'for a not-published course' do
    let(:published) { false }
    let(:start_date) { nil }
    let(:display_start_date) { 1.day.from_now }

    it 'removes an previous date' do
      CourseService::NextDate.create! attrs.merge(date: 2.days.from_now)

      expect { perform }.to change(CourseService::NextDate, :count).from(1).to(0)
    end

    it 'does not create a date' do
      perform

      expect(CourseService::NextDate.count).to eq 0
    end
  end
end
