# frozen_string_literal: true

require 'spec_helper'

describe 'Grants: List', type: :request do
  subject(:resource) { api.rel(:grants).get(params).value! }

  let(:api)     { Restify.new(:test).get.value! }
  let(:params)  { {} }

  let!(:grants) { create_list(:grant, 5) }

  it 'responds with :ok' do
    expect(resource).to respond_with :ok
  end

  it 'returns grant list' do
    expect(resource).to eq json(grants)
  end

  context 'with filter' do
    let(:role)       { create(:role, name: 'the-role') }
    let(:context_id) { SecureRandom.uuid }
    let(:context)    { create(:context, id: context_id) }

    describe 'by role' do
      let!(:grants_with_role) { create(:grant, role:) }
      let(:params) { {role: 'the-role'} }

      it 'returns the filtered grant list' do
        expect(resource).to eq json([grants_with_role])
      end
    end

    describe 'by context' do
      let!(:grants_in_context) { create(:grant, context:) }
      let(:params) { {context: context_id} }

      it 'returns the filtered grant list' do
        expect(resource).to eq json([grants_in_context])
      end
    end

    describe 'by role and context' do
      let!(:grants_with_role_in_context) { create(:grant, role:, context:) }
      let(:params) { {role: role.name, context: context_id} }

      it 'returns the filtered grant list' do
        expect(resource).to eq json([grants_with_role_in_context])
      end
    end
  end
end
