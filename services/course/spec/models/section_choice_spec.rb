# frozen_string_literal: true

require 'spec_helper'

describe SectionChoice, type: :model do
  subject { section_choice }

  let!(:section_choice) { create(:'course_service/section_choice') }

  it { is_expected.not_to accept_values_for(:user_id, nil) }
  its(:choice_ids) { is_expected.to eq [] }

  it 'does not allow duplicate section choices scoped to the user ID (case-insensitive)' do
    section = create(:'course_service/section')
    user_id = generate(:user_id)
    create(:'course_service/section_choice', section_id: section.id, user_id:)

    expect do
      create(:'course_service/section_choice', section_id: section.id, user_id:)
    end.to raise_error(ActiveRecord::RecordInvalid, /Section has already been taken/)

    expect do
      create(:'course_service/section_choice', section_id: section.id, user_id: generate(:user_id))
    end.not_to raise_error
  end
end
