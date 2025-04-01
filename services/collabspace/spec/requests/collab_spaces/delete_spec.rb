# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Spaces: Delete', type: :request do
  subject(:delete_request) { api.rel(:collab_space).delete({id: collab_space.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:collab_space) { create(:collab_space) }

  it 'changes the number of collab spaces' do
    expect { delete_request }.to change(CollabSpace, :count).from(1).to(0)
  end
end
