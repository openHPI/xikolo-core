# frozen_string_literal: true

require 'spec_helper'

describe 'Memberships: Deletion', type: :request do
  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:user) { create(:'account_service/user') }
  let(:group) { create(:'account_service/group') }

  describe '#destroy' do
    context 'w/ membership' do
      subject(:resource) { api.rel(:membership).delete({id: membership}).value! }

      let!(:membership) { create(:'account_service/membership', user:, group:) }

      it 'responds with 200 Ok' do
        expect(resource).to respond_with :ok
      end

      it 'responds with membership resource' do
        expect(resource).to eq json(membership)
      end

      it 'destroys database record' do
        expect { resource }.to change(AccountService::Membership, :count).from(1).to(0)
      end
    end

    context 'w/o membership' do
      subject(:resource) do
        api.rel(:membership)
          .delete({id: '0fe85664-492e-4a5c-a4ba-8270692a0ad8'})
          .value!
      end

      it 'responds with 204 No Content' do
        expect(resource).to respond_with :no_content
      end
    end
  end

  describe '#delete' do
    context 'w/ membership' do
      subject(:resource) do
        api.rel(:memberships).delete({user:, group:}).value!
      end

      let!(:membership) { create(:'account_service/membership', user:, group:) }

      it 'responds with 200 Ok' do
        expect(resource).to respond_with :ok
      end

      it 'responds with membership resource' do
        expect(resource).to match_array json([membership])
      end

      it 'destroys database record' do
        expect { resource }.to change(AccountService::Membership, :count).from(1).to(0)
      end
    end

    context 'w/o membership' do
      subject(:resource) do
        api.rel(:memberships).delete({user:, group:}).value!
      end

      it 'responds with 200 Ok' do
        expect(resource).to respond_with :ok
      end

      it 'has no content' do
        expect(resource).to eq []
      end
    end

    context 'w/o user' do
      subject(:resource) { api.rel(:memberships).delete({group:}).value! }

      it 'responds with 404 Not Found' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end

    context 'w/o group' do
      subject(:resource) { api.rel(:memberships).delete({user:}).value! }

      it 'responds with 404 Not Found' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end

    context 'w/o group and user' do
      subject(:resource) { api.rel(:memberships).delete.value! }

      it 'responds with 404 Not Found' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end
end
