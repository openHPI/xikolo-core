# frozen_string_literal: true

require 'spec_helper'

describe CourseService::ChannelDecorator do
  subject(:json) { decorator.as_json(api_version: 1).stringify_keys }

  let(:channel) { create(:'course_service/channel', :full_blown) }
  let(:decorator) { described_class.new(channel) }

  it 'exports default fields' do
    expect(json.keys).to match_array %w[
      id
      code
      title
      title_translations
      logo_url
      description
      stage_visual_url
      mobile_visual_url
      stage_statement
      public
      highlight
      affiliated
      position
      url
      info_link
    ]
  end

  it { is_expected.to include 'id' => channel.id }
  it { is_expected.to include 'code' => channel.code }
  it { is_expected.to include 'title' => channel.title }
  it { is_expected.to include 'title_translations' => channel.title_translations }
  it { is_expected.to include 'logo_url' => channel.logo_url }
  it { is_expected.to include 'description' => channel.description }
  it { is_expected.to include 'stage_visual_url' => channel.stage_visual_url }
  it { is_expected.to include 'mobile_visual_url' => channel.stage_visual_url }
  it { is_expected.to include 'stage_statement' => channel.stage_statement }
  it { is_expected.to include 'public' => channel.public }
  it { is_expected.to include 'highlight' => channel.highlight }
  it { is_expected.to include 'affiliated' => channel.affiliated }
  it { is_expected.to include 'position' => channel.position }
  it { is_expected.to include 'info_link' => channel.info_link }
end
