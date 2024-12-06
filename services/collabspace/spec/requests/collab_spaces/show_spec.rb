# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Spaces: Show', type: :request do
  subject { api.rel(:collab_space).get(id: collab_space.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:collab_space) { create(:collab_space) }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it { is_expected.to include('id') }
    it { is_expected.to include('name') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('is_open') }
    it { is_expected.to include('description') }
    it { is_expected.to include('details') }
    it { is_expected.to have_relation('memberships') }
  end
end
