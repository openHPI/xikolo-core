# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Spaces: Update', type: :request do
  subject(:update_request) { api.rel(:collab_space).patch(params, id: collab_space.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:collab_space) { create(:collab_space) }
  let(:params) { {name: 'changed'} }

  it 'changes the name of the collab space' do
    expect { update_request }.to change { collab_space.reload.name }.to eq params[:name]
  end

  it 'does not change other attributes like course_id' do
    expect { update_request }.not_to change { collab_space.reload.course_id }
  end
end
