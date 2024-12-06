# frozen_string_literal: true

require 'spec_helper'

describe EnrollmentDecorator do
  subject(:json) { decorator.as_json(api_version: 1).stringify_keys }

  let(:enrollment) { create(:enrollment) }
  let(:decorator) { described_class.new(enrollment) }

  it 'includes expected keys' do
    expect(json.keys).to match_array %w[
      id
      course_id
      user_id
      url
      deleted
      created_at
      updated_at
      proctored
      forced_submission_date
      reactivations_url
    ]
  end

  it 'has a relation to reactivations' do
    expect(json['reactivations_url']).to eq enrollment_reactivations_path(enrollment)
  end

  it 'does not have a forced_submission_date' do
    expect(json['forced_submission_date']).to be_nil
  end

  context 'as_event' do
    subject(:json) { decorator.as_event.stringify_keys }

    its(:keys) do
      is_expected.to match_array %w[
        id
        course_id
        user_id
        created_at
        updated_at
        proctored
        deleted
        forced_submission_date
      ]
    end
  end

  context 'with forced_submission_date' do
    let(:now) { Time.zone.now }
    let(:enrollment) { create(:enrollment, forced_submission_date: now) }

    it 'has a forced_submission_date' do
      expect(json['forced_submission_date']).not_to be_nil
      expect(Time.zone.parse(json['forced_submission_date'])).to eq Time.zone.parse(now.to_s)
    end
  end
end
