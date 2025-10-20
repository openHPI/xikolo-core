# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::SectionStartSyncWorker, type: :worker do
  let(:section) do
    create(:'course_service/section',
      course:,
      start_date:)
  end
  let(:course) { create(:'course_service/course', status: 'active') }
  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(section.id), 'section_start').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'user_id' => '00000000-0000-0000-0000-000000000000',
      'type' => 'section_start',
      'course_id' => section.course_id,
      'resource_type' => 'section',
      'resource_id' => section.id,
      'title' => section.title,
      'section_pos' => section.position,
      'item_pos' => 0,
    }
  end

  def execute
    section
    Sidekiq::Testing.inline! do
      described_class.perform_async(section.id)
    end
  end

  it 'does not fail for unknown sections' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(0)
  end

  context 'for published section in not-started course' do
    let(:course) { create(:'course_service/course', display_start_date: course_start_date) }
    let(:course_start_date) { 2.days.from_now }
    let(:start_date) { 3.days.from_now }

    it 'creates an next date' do
      execute

      expect(NextDate.count).to eq 1
      date = NextDate.first
      expect(date.attributes).to include attrs
      expect(date.date).to be_within(0.000001).of(start_date)
      expect(date.visible_after).to be_within(0.000001).of(course_start_date)
    end
  end

  context 'for active section' do
    let(:start_date) { 1.day.from_now }

    it 'creates an next date' do
      execute

      expect(NextDate.count).to eq 1
      date = NextDate.first
      expect(date.attributes).to include attrs
      expect(date.date).to be_within(0.000001).of(start_date)
    end
  end
end
