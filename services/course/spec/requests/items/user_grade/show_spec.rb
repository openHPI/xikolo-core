# frozen_string_literal: true

require 'spec_helper'

describe 'Item User Grade: Show', type: :request do
  subject(:resource) { item_api.rel(:user_grade).get({user_id:}).value! }

  let(:api) { Restify.new(course_service.root_url).get.value! }
  let(:item_api) { api.rel(:item).get({id: item.id}).value! }
  let(:user_id) { generate(:user_id) }

  context 'a homework' do
    let!(:item) { create(:'course_service/item', :homework) }

    context 'when the user has not yet submitted anything' do
      it 'responds with 404 Not Found' do
        expect { resource }.to raise_error(Restify::NotFound)
      end
    end

    context 'when there are results for the user' do
      before { create(:'course_service/result', item:, user_id:, dpoints: 30) }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq('points' => 3.0) }
    end
  end

  context 'a bonus exercise' do
    let!(:item) { create(:'course_service/item', :bonus) }

    context 'when the user has not yet submitted anything' do
      it 'responds with 404 Not Found' do
        expect { resource }.to raise_error(Restify::NotFound)
      end
    end

    context 'when there are results for the user' do
      before { create(:'course_service/result', item:, user_id:, dpoints: 30) }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq('points' => 3.0) }
    end
  end
end
