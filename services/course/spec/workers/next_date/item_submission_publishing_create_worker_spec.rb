# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::ItemSubmissionPublishingCreateWorker, type: :worker do
  let(:course) { create(:'course_service/course', status: 'active') }
  let(:section) { create(:'course_service/section', published: true, course:) }
  let(:item) { create(:'course_service/item', section:, published: true, submission_deadline: 1.day.from_now, submission_publishing_date:) }
  let(:submission_publishing_date) { nil }
  let(:user_id) { generate(:user_id) }

  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(item.id), 'item_submission').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'user_id' => user_id,
      'type' => 'item_submission_publishing',
      'course_id' => course.id,
      'resource_type' => 'item',
      'resource_id' => item.id,
      'title' => "#{section.title}: #{item.title}",
      'section_pos' => section.position,
      'item_pos' => item.position,
    }
  end

  before do
    item
    Sidekiq::Testing.inline! do
      NextDate::ItemSubmissionDeadlineSyncWorker.perform_async(item.id)
    end
    expect(NextDate.count).to eq 1
  end

  def execute
    Sidekiq::Testing.inline! do
      described_class.perform_async(item.id, user_id)
    end
  end

  it 'does not fail for unknown item' do
    expect(NextDate.count).to eq(1)

    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid, SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(1)
  end

  context 'for item with submission_publishing_date' do
    let(:submission_publishing_date) { 3.days.from_now }

    it 'creates an next date' do
      expect { execute }.to change(NextDate, :count).by(1)

      date = NextDate.where(user_id:).first
      expect(date.attributes).to include attrs
      expect(date.date).to be_within(0.000001).of(submission_publishing_date)
    end
  end

  context 'for item without submission_publishing_date' do
    let(:submission_publishing_date) { nil }

    it 'creates an next date' do
      expect { execute }.to change(NextDate, :count).by(1)

      date = NextDate.where(user_id:).first
      expect(date.attributes).to include attrs
    end
  end
end
