# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Course::Channel, '#stage_courses', type: :model do
  subject(:stage_courses) { channel.stage_courses }

  let(:channel) do
    create(:channel).tap do |channel|
      channel.courses << create(:course, :preparing, show_on_stage: true)
      channel.courses << create(:course, :active, show_on_stage: true)
      channel.courses << create(:course, :active, :hidden, show_on_stage: true)
      channel.courses << create(:course, :active, :deleted, show_on_stage: true)
      channel.courses << create(:course, :active, groups: %w[group.1], show_on_stage: true)
      channel.courses << create(:course, :active, show_on_stage: false)
      channel.courses << create(:course, :archived, show_on_stage: true)
      create(:course, :active, show_on_stage: true)
    end
  end

  it 'returns all non-deleted, public, and unrestricted courses marked as stage item' do
    expect(stage_courses.length).to eq 2
    expect(stage_courses.pluck(:channel_id)).to all(eq channel.id)

    expect(stage_courses).to contain_exactly(
      an_object_having_attributes(status: 'active', deleted: false, show_on_stage: true),
      an_object_having_attributes(status: 'archive', deleted: false, show_on_stage: true)
    )
  end
end
