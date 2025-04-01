# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Spaces: Create', type: :request do
  subject(:create_request) { api.rel(:collab_spaces).post(payload).value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:payload) do
    {
      name: 'yolo',
      owner_id: '00000001-3100-4444-9999-000000000004',
      is_open: true,
      course_id: '00000001-3200-4444-9999-000000000003',
      description: 'you only live once',
      details: 'common slang term mostly used by young people',
    }
  end

  it { is_expected.to respond_with :created }

  it 'returns the URL of created resource in Location header' do
    expect(create_request.response.headers['LOCATION']).to end_with collab_space_path(CollabSpace.first)
  end

  context 'with invalid data' do
    let(:payload) { {} }

    it 'responds with 422 Unprocessable Entity' do
      expect { create_request }.to raise_error(Restify::UnprocessableEntity)
    end
  end

  it 'creates a new collab space' do
    expect { create_request }.to change(CollabSpace, :count).from(0).to(1)
  end

  describe 'the new collab space' do
    subject(:new_collab_space) { create_request; CollabSpace.first }

    describe '(attributes)' do
      it 'has the correct course_id' do
        expect(new_collab_space.course_id).to eq payload[:course_id]
      end

      it 'has the correct name' do
        expect(new_collab_space.name).to eq payload[:name]
      end

      it 'has the correct open state' do
        expect(new_collab_space.is_open).to eq payload[:is_open]
      end

      it 'has the correct description' do
        expect(new_collab_space.description).to eq payload[:description]
      end

      it 'has the correct details' do
        expect(new_collab_space.details).to eq payload[:details]
      end
    end

    it 'makes the owner admin' do
      expect(new_collab_space.memberships.first.status).to eq 'admin'
    end

    context 'when creating a team' do
      let(:payload) { super().merge(kind: 'team', is_open: false) }

      it { is_expected.to be_team }
    end
  end
end
