# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemDecorator, type: :decorator do
  let(:item) { create(:item) }
  let(:decorator) { item.decorate }

  context 'as_json' do
    subject(:json_response) { decorator.as_json({}).stringify_keys }

    it 'serializes resource as JSON' do
      expect(json_response).to eq(
        'calculated_time_effort' => item.calculated_time_effort,
        'content_id' => item.content_id,
        'content_type' => item.content_type,
        'course_id' => item.course_id,
        'id' => item.id,
        'section_id' => item.section_id,
        'time_effort' => item.time_effort,
        'time_effort_overwritten' => item.time_effort_overwritten,
        'overwritten_time_effort_url' => "http://test.host/items/#{item.id}/overwritten_time_effort"
      )
    end
  end
end
