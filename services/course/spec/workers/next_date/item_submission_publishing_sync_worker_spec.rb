# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::ItemSubmissionPublishingSyncWorker, type: :worker do
  let(:course) { create(:course, status: 'active') }
  let(:section) { create(:section, published: true, course:) }
  let(:item) { create(:item, section:, published: true, submission_deadline:, submission_publishing_date:) }
  let(:submission_deadline) { 1.day.from_now }
  let(:submission_publishing_date) { 3.days.from_now }
  let(:user_ids) { generate_list(:user_id, 5) }

  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(item.id), 'item_submission').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'type' => 'item_submission_publishing',
      'course_id' => course.id,
      'resource_type' => 'item',
      'resource_id' => item.id,
      'title' => "#{section.title}: #{item.title}",
      'section_pos' => section.position,
      'item_pos' => item.position,
    }
  end

  it 'does not fail for unknown item' do
    expect(NextDate.count).to eq(0)

    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(0)
  end

  it 'updates attributes (like title) of all created next dates' do
    item
    Sidekiq::Testing.inline! do
      NextDate::ItemSubmissionDeadlineSyncWorker.perform_async(item.id)
    end
    # Expect a NextDate for the item's submission deadline to exist
    expect(NextDate.count).to eq 1
    user_ids.map do |user_id|
      NextDate.create! attrs.merge(title: 'Test', user_id:, date: 2.days.from_now)
    end
    expect(NextDate.count).to eq 6
    expect(NextDate.pluck(:title)).to include('Test')

    Sidekiq::Testing.inline! do
      described_class.perform_async(item.id)
    end

    expect(NextDate.count).to eq 6
    expect(NextDate.pluck(:title)).not_to include('Test')
  end

  def execute
    item
    Sidekiq::Testing.inline! do
      described_class.perform_async(item.id)
    end
  end

  context 'for item with submission_deadline' do
    before do
      user_ids.map do |user_id|
        NextDate.create! attrs.merge(date: 2.days.from_now, user_id:)
      end
    end

    it 'updates the NextDates but does not remove any' do
      expect { execute }.not_to change(NextDate, :count)
    end

    context 'without submission_publishing_date' do
      let(:submission_publishing_date) { nil }

      it 'keeps the NextDates to cover `item_submission_deadline` next dates' do
        expect { execute }.not_to change(NextDate, :count)
      end
    end
  end

  context 'for item without submission_deadline and submission_publishing_date' do
    let(:submission_deadline) { nil }
    let(:submission_publishing_date) { nil }

    before do
      user_ids.map do |user_id|
        NextDate.create! attrs.merge(date: 2.days.from_now, user_id:)
      end
    end

    it 'removes the next dates' do
      expect { execute }.to change(NextDate, :count).from(5).to(0)
    end
  end
end
