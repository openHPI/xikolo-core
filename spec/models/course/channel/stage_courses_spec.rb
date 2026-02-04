# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Course::Channel, '#stage_courses', type: :model do
  subject(:stage_courses) { channel.stage_courses }

  let(:channel) do
    create(:channel).tap do |channel|
      create(:course, :preparing, show_on_stage: true, channels: [channel])
      create(:course, :active, show_on_stage: true, channels: [channel])
      create(:course, :active, :hidden, show_on_stage: true, channels: [channel])
      create(:course, :active, :deleted, show_on_stage: true, channels: [channel])
      create(:course, :active, groups: %w[group.1], show_on_stage: true, channels: [channel])
      create(:course, :active, show_on_stage: false, channels: [channel])
      create(:course, :archived, show_on_stage: true, channels: [channel])
      create(:course, :active, show_on_stage: true)
    end
  end

  it 'returns all non-deleted, public, and unrestricted courses marked as stage item' do
    expect(stage_courses.length).to eq 2
    expect(stage_courses.first.channels.first.id).to eq channel.id
    expect(stage_courses.second.channels.first.id).to eq channel.id

    expect(stage_courses).to contain_exactly(
      an_object_having_attributes(status: 'active', deleted: false, show_on_stage: true),
      an_object_having_attributes(status: 'archive', deleted: false, show_on_stage: true)
    )
  end
end
