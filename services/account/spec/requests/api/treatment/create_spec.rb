# frozen_string_literal: true

require 'spec_helper'

describe 'Create treatments', type: :request do
  subject(:resource) { api.rel(:treatments).post(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { attributes_for(:treatment) }

  it { is_expected.to respond_with :created }

  it 'create new record' do
    expect { resource }.to change(Treatment, :count).from(0).to(1)
  end

  describe '<response>' do
    let(:record) { Treatment.last }

    it 'responds with new treatment' do
      expect(resource).to match an_object_having_attributes(
        name: record.name,
        required: false,
        consent_manager: {},
        self_url: treatment_url(record)
      )
    end
  end
end
