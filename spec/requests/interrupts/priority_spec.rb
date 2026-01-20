# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Priority of multiple interrupts', type: :request do
  subject(:request) do
    get '/', headers: {
      'Authorization' => "Xikolo-Session session_id=#{stub_session_id}",
    }
  end

  before do
    stub_user_request(
      id: '2611b7f0-b0dc-43d3-96be-81d810ba2535',
      interrupts:
    )
  end

  let(:interrupts) { [] }

  context 'in order of priority' do
    let(:interrupts) { %w[new_consents new_policy] }

    it 'redirects to the most important interrupt (new consent required)' do
      request
      expect(response).to redirect_to '/treatments'
    end
  end

  context 'in different order' do
    let(:interrupts) { %w[new_policy new_consents] }

    it 'still redirects to the most important interrupt (new consent required)' do
      request
      expect(response).to redirect_to '/treatments'
    end
  end
end
