# frozen_string_literal: true

require 'spec_helper'

describe 'Users: Features: Delete', type: :request do
  subject(:resource) { base.rel(:features).delete({name: features[2].name}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }
  let(:user) { create(:user) }

  let!(:features) do
    [
      create_list(:feature, 2),
      create_list(:feature, 2, owner: user),
      create_list(:feature, 2),
    ].flatten
  end

  it 'responds with 204 No Content' do
    expect(resource).to respond_with :no_content
  end

  it 'removes feature record' do
    expect { resource }.to change {
      Feature.exists?(features[2].id)
    }.from(true).to(false)
  end
end
