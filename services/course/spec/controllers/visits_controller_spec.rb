# frozen_string_literal: true

require 'spec_helper'

describe VisitsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:item) { create(:item) }

  describe '#create' do
    subject(:creation) { post :create, params: }

    let(:params) { {item_id: item.id, user_id: generate(:user_id)} }

    context 'with valid params' do
      context 'without visit existing for course item' do
        it { is_expected.to be_successful }

        it 'stores a new visit' do
          expect { creation }.to change(Visit, :count).from(0).to(1)
        end
      end

      context 'with visit already existing for course item' do
        let!(:visit) { create(:visit, item:, user_id: params[:user_id]) }
        let(:create_time) { visit.updated_at }
        let(:recreate_time) { Time.now.utc + 10.minutes }

        before { Timecop.travel(recreate_time) }
        after { Timecop.return }

        it { is_expected.to be_successful }

        it 'does not create another visit' do
          expect { creation }.not_to change(Visit, :count)
        end

        it 'updates the last visit time on the existing record' do
          expect { creation }.to change { visit.reload.last_visited }
            .from(a_value_within(0.1).of(create_time))
            .to(a_value_within(0.1).of(recreate_time))
        end
      end
    end
  end
end
