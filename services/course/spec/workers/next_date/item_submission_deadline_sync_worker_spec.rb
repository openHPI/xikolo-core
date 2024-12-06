# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::ItemSubmissionDeadlineSyncWorker, type: :worker do
  let(:course) { create(:course, status: 'active') }
  let(:section) { create(:section, published: true, course:) }
  let(:item) { create(:item, section:, published: true, submission_deadline:) }
  let(:submission_deadline) { nil }
  let(:user_id) { generate(:user_id) }

  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(item.id), 'item_submission').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'user_id' => '00000000-0000-0000-0000-000000000000',
      'type' => 'item_submission_deadline',
      'course_id' => course.id,
      'resource_type' => 'item',
      'resource_id' => item.id,
      'title' => "#{section.title}: #{item.title}",
      'section_pos' => section.position,
      'item_pos' => item.position,
    }
  end

  before do
    NextDate.create! attrs.merge(date: 2.days.from_now, user_id:)
  end

  def execute
    item
    Sidekiq::Testing.inline! do
      described_class.perform_async(item.id)
    end
  end

  it 'does not fail for unknown item' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(1)
  end

  context 'for item with submission_deadline' do
    let(:submission_deadline) { 3.days.from_now }

    it 'creates an next date' do
      expect { execute }.to change(NextDate, :count).by(1)

      date = NextDate.where(user_id: NextDate.nil_user_id).first
      expect(date.attributes).to include attrs
      expect(date.date).to be_within(0.000001).of(submission_deadline)
    end
  end

  context 'for item without submission_deadline' do
    let(:submission_deadline) { nil }

    it 'removes an previous date and user override' do
      NextDate.create! attrs.merge(date: 2.days.from_now)

      expect { execute }.to change(NextDate, :count).from(2).to(0)
    end

    it 'does not create a date' do
      expect(NextDate.count).to eq 1

      execute

      expect(NextDate.count).to eq 0
    end
  end
end
