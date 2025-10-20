# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::CourseStartSyncWorker, type: :worker do
  let(:course) do
    create(:'course_service/course',
      status: course_status,
      display_start_date:,
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

  def execute
    course
    Sidekiq::Testing.inline! do
      described_class.perform_async(course.id)
    end
  end

  it 'does not fail for unknown courses' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(0)
  end

  context 'for a published course' do
    let(:course_status) { 'active' }

    context 'with previously created date' do
      let(:start_date) { nil }
      let(:display_start_date) { 1.day.from_now }

      it 'updates an previous date' do
        NextDate.create! attrs.merge(date: 2.days.from_now)

        expect { execute }.not_to change(NextDate, :count)
        date = NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(display_start_date)
      end
    end

    context 'with display start date' do
      let(:start_date) { 1.day.ago }
      let(:display_start_date) { 1.day.from_now }

      it 'creates an next date' do
        execute

        expect(NextDate.count).to eq 1
        date = NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(display_start_date)
      end
    end

    context 'without display but start date' do
      let(:start_date) { 1.day.from_now }
      let(:display_start_date) { nil }

      it 'creates an next date' do
        execute

        expect(NextDate.count).to eq 1
        date = NextDate.first
        expect(date.attributes).to include attrs
        expect(date.date).to be_within(0.000001).of(start_date)
      end
    end

    context 'without display and start date' do
      let(:start_date) { nil }
      let(:display_start_date) { nil }

      it 'creates an next date' do
        execute

        expect(NextDate.count).to eq 0
      end
    end
  end

  context 'for a not-published course' do
    let(:course_status) { 'preparation' }
    let(:start_date) { nil }
    let(:display_start_date) { 1.day.from_now }

    it 'removes an previous date' do
      NextDate.create! attrs.merge(date: 2.days.from_now)

      expect { execute }.to change(NextDate, :count).from(1).to(0)
    end

    it 'does not create a date' do
      execute

      expect(NextDate.count).to eq 0
    end
  end
end
