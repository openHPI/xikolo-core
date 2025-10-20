# frozen_string_literal: true

require 'spec_helper'

describe 'Results: Update', type: :request do
  let(:api) { Restify.new(:test).get.value! }
  let(:result_id) { SecureRandom.uuid }
  let(:user_id) { generate(:user_id) }
  let!(:item) { create(:'course_service/item') }

  describe '(via PATCH)' do
    subject(:update) { api.rel(:result).patch(data, params: {id: result_id}).value! }

    let(:data) { {user_id:, item_id: item.id, points: 2.3} }

    context 'with existing resource' do
      let!(:result) { Result.create id: result_id, user_id:, item_id: item.id, dpoints: 34 }

      it { is_expected.to respond_with :no_content }

      it 'updates the result\'s dpoints' do
        expect { update }.to change { result.reload.dpoints }.from(34).to(23)
      end

      context 'with more than one decimal after the comma' do
        let(:data) { super().merge(points: 2.13) }

        it 'errors without side effects' do
          expect { update }.to raise_error(Restify::UnprocessableEntity) do |err|
            expect(err.errors).to eq 'points' => %w[invalid_format]
          end
          expect(result.reload.dpoints).to eq 34
        end
      end
    end

    context 'without existing resource' do
      it 'responds with 404 Not Found without side effects' do
        expect { update }.to raise_error(Restify::NotFound)
        expect(Result.count).to eq 0
      end
    end
  end

  describe '(via PUT)' do
    subject(:update) { api.rel(:result).put(data, params: {id: result_id}).value! }

    let(:data) { {user_id:, item_id: item.id, points: 2.3} }

    context 'with existing resource' do
      let(:result) { Result.create id: result_id, user_id:, item_id: item.id, dpoints: 34 }

      it { is_expected.to respond_with :no_content }

      it 'updates the result\'s dpoints' do
        expect { update }.to change { result.reload.dpoints }.from(34).to(23)
      end

      context 'with more than one decimal after the comma' do
        let(:data) { super().merge(points: 2.13) }

        it 'errors without side effects' do
          expect { update }.to raise_error(Restify::UnprocessableEntity) do |err|
            expect(err.errors).to eq 'points' => %w[invalid_format]
          end
          expect(result.reload.dpoints).to eq 34
        end
      end
    end

    describe 'without existing resource' do
      it { is_expected.to respond_with :no_content }

      it 'creates a result object' do
        expect { update }.to change(Result, :count).from(0).to(1)
      end

      it 'stores dpoints' do
        update
        expect(Result.find(result_id).dpoints).to eq 23
      end

      context 'with more than one decimal after the comma' do
        let(:data) { super().merge(points: 2.13) }

        it 'errors' do
          expect { update }.to raise_error(Restify::UnprocessableEntity) do |err|
            expect(err.errors).to eq 'points' => %w[invalid_format]
          end
        end
      end
    end
  end
end
