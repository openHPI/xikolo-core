# frozen_string_literal: true

require 'spec_helper'

describe API::PasswordResetsController, type: :controller do
  describe '#create' do
    subject(:response) { post :create, params: }

    let(:params) { {} }

    context 'with existing email address' do
      let(:user) { create(:user) }
      let(:params) { {email: user.email} }

      it { is_expected.to have_http_status :created }

      it 'creates new password reset' do
        expect { response }.to change(PasswordReset, :count).from(0).to(1)
      end

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it { is_expected.to have_key 'id' }
        it { is_expected.to include 'user_id' => user.id }
      end
    end

    context 'with non-existing email address' do
      let(:params) { {email: 'does.not.exists@xikolo.de'} }

      it { is_expected.to have_http_status :unprocessable_entity }

      it 'does not create a password reset' do
        expect { response }.not_to change(PasswordReset, :count)
      end

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it 'include error messages' do
          expect(json['errors']).not_to be_empty
        end
      end
    end
  end

  describe '#show' do
    subject(:response) { get :show, params: {id: reset.token} }

    let(:reset) { create(:password_reset) }

    it { is_expected.to have_http_status :ok }

    describe 'JSON' do
      subject(:json) { JSON.parse(response.body) }

      it { is_expected.to include 'id' => reset.token }
    end
  end

  describe '#update' do
    subject(:response) { patch :update, params: }

    let(:user) { create(:user) }
    let(:reset) { create(:password_reset, user:) }
    let(:params) { {id: reset.token} }

    context 'without password' do
      it { is_expected.to have_http_status :unprocessable_entity }
    end

    context 'with empty password' do
      let(:params) { {**super(), password: ''} }

      it { is_expected.to have_http_status :unprocessable_entity }

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it 'includes password missing errors message' do
          expect(json['errors']).to include 'password' => ['missing']
        end
      end
    end

    context 'with too short password' do
      let(:params) { {**super(), password: 'test'} }

      it { is_expected.to have_http_status :unprocessable_entity }

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it 'includes password below_minimum_length error message' do
          expect(json['errors']).to include 'password' => ['below_minimum_length']
        end
      end
    end

    context 'with valid password' do
      let(:params) { {**super(), password: 'new secret'} }

      it { is_expected.to have_http_status :ok }

      it 'changes user password' do
        expect { response }.to change {
          user.reload.authenticate('new secret')
        }.from(false).to(user)
      end

      it 'removes reset token after use' do
        expect { response }.to \
          change(PasswordReset.where(id: reset.id), :count)
          .from(1)
          .to(0)
      end

      context 'with another reset token for same user' do
        before do
          reset
          create(:password_reset, user:)

          # Ensure setup is as expected
          expect(user.password_resets.count).to eq 2
        end

        it 'removes all tokens' do
          expect { response }.to \
            change(user.password_resets, :count).from(2).to(0)
        end
      end

      context 'with expired reset token' do
        before { reset.update! created_at: 24.hours.ago }

        it { is_expected.to have_http_status :unprocessable_entity }

        describe 'JSON' do
          subject(:json) { JSON.parse(response.body) }

          it 'has a token expired errors message' do
            expect(json['errors']).to include 'base' => ['expired']
          end
        end
      end
    end
  end
end
