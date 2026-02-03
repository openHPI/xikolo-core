# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Item: overwrite_time_effort', type: :request do
  subject(:overwrite_effort) do
    api.rel(:item_overwritten_time_effort).put(payload, params: {item_id: item.id}).value!
  end

  let(:api) { restify_with_headers(timeeffort_service_url).get.value! }
  let(:item_id) { '00000001-3300-4444-9999-000000000001' }
  let(:old_time_effort) { 22 }
  let(:new_time_effort) { 55 }
  let(:item) { create(:'timeeffort_service/item', id: item_id, time_effort: old_time_effort) }
  let(:payload) { {time_effort: new_time_effort} }
  let(:overwrite_time_effort_operation) { instance_double(TimeeffortService::Operation) }

  context 'w/o time_effort present' do
    let(:payload) { super().merge(time_effort: nil) }

    it 'responds with 422 Unprocessable Entity' do
      expect { overwrite_effort }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'time_effort_required'
      end
    end
  end

  context 'w/ existing item' do
    let(:patch_item_status) { 204 }
    let!(:course_item_stub) do
      Stub.request(
        :course, :patch, "/items/#{item.id}",
        body: hash_including(time_effort: payload[:time_effort])
      ).to_return Stub.response(status: patch_item_status)
    end

    before do
      allow(TimeeffortService::Item).to receive(:find).with(item.id).and_return(item)
      expect(item).to receive(:overwrite_time_effort).once
        .with(payload[:time_effort])
        .and_return overwrite_time_effort_operation
    end

    context 'w/ overwrite_time_effort success' do
      before do
        allow(overwrite_time_effort_operation).to receive(:success?).and_return true
      end

      it 'does patch the course item' do
        overwrite_effort
        expect(course_item_stub).to have_been_requested
      end

      it 'responds with 204 No Content' do
        expect(overwrite_effort.response.status).to eq :no_content
      end

      context 'w/o patch item success' do
        let(:patch_item_status) { 404 }

        it 'responds with 422 Unprocessable Entity' do
          expect { overwrite_effort }.to raise_error(Restify::ClientError) do |error|
            expect(course_item_stub).to have_been_requested
            expect(error.status).to eq :unprocessable_content
          end
        end
      end
    end

    context 'w/o overwrite_time_effort success' do
      before do
        allow(overwrite_time_effort_operation).to receive(:success?).and_return false
      end

      it 'does not patch the course item' do
        expect { overwrite_effort }.to raise_error(Restify::ClientError) do
          expect(course_item_stub).not_to have_been_requested
        end
      end

      it 'responds with 422 Unprocessable Entity' do
        expect { overwrite_effort }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :unprocessable_content
          expect(error.errors).to eq 'overwrite_time_effort_error'
        end
      end
    end
  end
end
