# frozen_string_literal: true

RSpec.shared_examples 'an authorization provider' do
  context 'with new authorization' do
    it 'responds with 422 Unprocessable Entity' do
      expect(response).to respond_with :unprocessable_content
    end

    it 'does not create a user record' do
      expect { response }.not_to change(AccountService::User, :count)
    end

    it 'does not create a session record do' do
      expect { response }.not_to change(AccountService::Session, :count)
    end

    it 'does not change the authorizations user' do
      expect { response }.not_to(change { authorization.reload.user_id })
    end

    describe 'payload error messages' do
      subject(:errors) { response.decoded_body['errors'] }

      it { is_expected.to include 'authorization' => ['user_creation_required'] }
    end

    context 'with autocreate parameter' do
      let(:payload) { {**super(), autocreate: true} }

      it 'responds with 201 Created' do
        expect(response).to respond_with :created
      end

      it 'creates a user record' do
        expect { response }.to change(AccountService::User, :count).from(0).to(1)
      end

      it 'creates a session record' do
        expect { response }.to change(AccountService::Session, :count).from(0).to(1)
      end

      it 'assigns the authorization to the user' do
        expect { response }.to change { authorization.reload.user_id }.from(nil)
      end

      describe 'created user record' do
        subject(:user) { authorization.reload.user }

        before { response }

        describe '#email' do
          subject { user.email }

          it { is_expected.to eq authorization.info[:email] }
        end

        describe '#full_name' do
          subject { user.full_name }

          it { is_expected.to eq full_name }
        end
      end
    end
  end
end
