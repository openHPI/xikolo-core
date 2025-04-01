# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item: Create', type: :request do
  subject(:create_item) { api.rel(:items).post(payload).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:item_id) { SecureRandom.uuid }
  let(:content_id) { SecureRandom.uuid }
  let(:section_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:payload) do
    {
      id: item_id,
      content_type: 'quiz',
      content_id:,
      section_id:,
      course_id:,
    }
  end

  it 'creates new item record' do
    expect { create_item }.to change(Item, :count).from(0).to(1)
  end

  it 'responds without a follow location' do
    expect(create_item.follow).to eq item_url(Item.last)
  end

  it 'returns item resource' do
    expect(create_item.to_h).to eq \
      'id' => payload[:id],
      'content_type' => payload[:content_type],
      'content_id' => payload[:content_id],
      'section_id' => payload[:section_id],
      'course_id' => payload[:course_id],
      'time_effort' => nil,
      'calculated_time_effort' => nil,
      'time_effort_overwritten' => false,
      'overwritten_time_effort_url' => "http://test.host/items/#{payload[:id]}/overwritten_time_effort"
  end

  context 'w/ time effort overwritten' do
    let(:payload) { super().merge(time_effort: 20, time_effort_overwritten: true) }

    it 'overwrites the default value for auto_calculate' do
      expect(create_item.to_h).to eq \
        'id' => payload[:id],
        'content_type' => payload[:content_type],
        'content_id' => payload[:content_id],
        'section_id' => payload[:section_id],
        'course_id' => payload[:course_id],
        'time_effort' => 20,
        'calculated_time_effort' => nil,
        'time_effort_overwritten' => true,
        'overwritten_time_effort_url' => "http://test.host/items/#{payload[:id]}/overwritten_time_effort"
    end
  end
end
