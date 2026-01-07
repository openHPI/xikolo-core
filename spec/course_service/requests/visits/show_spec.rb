# frozen_string_literal: true

require 'spec_helper'

describe 'Visit: Show', type: :request do
  subject(:action) { api.rel(:item_user_visit).get(params).value! }

  let(:visit) { create(:'course_service/visit') }
  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let(:params) { {item_id: visit.item_id, user_id: visit.user_id} }

  it { is_expected.to respond_with :ok }

  context 'with invalid parameters' do
    let(:params) { {item_id: 'foo', user_id: 'bar'} }

    it 'returns with 404' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end
end
