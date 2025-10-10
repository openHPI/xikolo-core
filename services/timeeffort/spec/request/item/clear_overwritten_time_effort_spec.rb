# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item: clear_overwritten_time_effort', type: :request do
  subject(:clear_effort) do
    api.rel(:item_overwritten_time_effort).delete({item_id: item.id}).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:item_id) { '00000001-3300-4444-9999-000000000001' }
  let(:item) { create(:item, id: item_id) }

  context 'w/o time effort_overwritten' do
    it 'responds with the unchanged item' do
      expect(clear_effort.to_hash).to include json \
        'calculated_time_effort' => item.calculated_time_effort,
        'content_id' => item.content_id,
        'content_type' => item.content_type,
        'course_id' => item.course_id,
        'id' => item.id,
        'section_id' => item.section_id,
        'time_effort' => item.time_effort,
        'time_effort_overwritten' => false
    end
  end

  context 'w/ time effort overwritten' do
    let(:item) { create(:item, :time_effort_overwritten, id: item_id) }
    let(:patch_item_status) { 204 }

    let!(:course_item_stub) do
      Stub.service(:course, build(:'course:root'))
      Stub.request(:course, :patch, "/items/#{item.id}",
        body: hash_including(time_effort: item.calculated_time_effort))
        .to_return Stub.response(status: patch_item_status)
    end

    it 'does patch the course item' do
      clear_effort
      expect(course_item_stub).to have_been_requested
    end

    context 'when patching the item fails' do
      let(:patch_item_status) { 404 }

      it 'responds with 422 Unprocessable Entity' do
        expect { clear_effort }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :unprocessable_content
        end
      end
    end
  end
end
