# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NextDate::OnDemandExpiresSyncWorker, type: :worker do
  let(:course) { create(:'course_service/course', status: 'active') }
  let(:enrollment) { create(:'course_service/enrollment', deleted:, course:, user_id:, forced_submission_date:) }
  let(:other_enrollment) { create(:'course_service/enrollment', course:) }
  let(:forced_submission_date) { nil }
  let(:deleted) { false }
  let(:user_id) { generate(:user_id) }
  let(:designated_id) { UUIDTools::UUID.sha1_create(UUIDTools::UUID.parse(course.id), 'on_demand_expires').to_s }
  let(:attrs) do
    # gold-standard how the core event attributes should look like
    {
      'slot_id' => designated_id,
      'user_id' => user_id,
      'type' => 'on_demand_expires',
      'course_id' => course.id,
      'resource_type' => 'on_demand',
      'resource_id' => course.id,
      'title' => course.title,
      'section_pos' => 0,
      'item_pos' => nil,
    }
  end

  let!(:other_next_date) { NextDate.create! attrs.merge(date: 2.days.from_now, user_id: other_enrollment.user_id) }

  def execute
    enrollment
    Sidekiq::Testing.inline! do
      described_class.perform_async(course.id, user_id)
    end
  end

  it 'does not fail for unknown enrollment' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(SecureRandom.uuid, SecureRandom.uuid)
    end

    expect(NextDate.count).to eq(1)
  end

  context 'for enrollment with forced_submission_date' do
    let(:forced_submission_date) { 3.days.from_now }

    it 'creates an next date' do
      expect(NextDate.count).to eq 1

      execute

      expect(NextDate.count).to eq 2
      date = NextDate.where.not(user_id: other_next_date.user_id).first
      expect(date.attributes).to include attrs
      expect(date.date).to be_within(0.000001).of(forced_submission_date)
    end
  end

  context 'for enrollment without forced_submission_date' do
    let(:forced_submission_date) { nil }

    it 'removes an previous date' do
      NextDate.create! attrs.merge(date: 2.days.from_now)

      expect { execute }.to change(NextDate, :count).from(2).to(1)
    end

    it 'does not create a date' do
      expect(NextDate.count).to eq 1

      execute

      expect(NextDate.count).to eq 1
    end
  end

  context 'deleted enrollment' do
    let(:forced_submission_date) { 3.days.from_now }
    let(:deleted) { true }
    let(:start_date) { 1.day.from_now }

    it 'removes an previous date' do
      NextDate.create! attrs.merge(date: 2.days.from_now)

      expect { execute }.to change(NextDate, :count).from(2).to(1)
    end

    it 'does not create a date' do
      expect(NextDate.count).to eq 1

      execute

      expect(NextDate.count).to eq 1
    end
  end
end
