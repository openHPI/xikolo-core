# frozen_string_literal: true

require 'spec_helper'

describe API::EmailsController, type: :controller do
  let(:user)  { create(:user) }
  let(:email) { create(:email, user:).reload }
  let(:params) { {} }

  describe '#index' do
    subject(:response) { get :index, params: }

    let(:params) { {user_id: email.user_id} }

    it { is_expected.to have_http_status :ok }

    describe 'JSON' do
      subject(:json) { JSON.parse(response.body) }

      it 'has two items' do
        expect(json.size).to eq 2
      end

      it 'is an email record' do
        expect(json).to include \
          'id' => email.reload.uuid,
          'address' => email.address,
          'confirmed' => true,
          'confirmed_at' => nil,
          'created_at' => email.created_at.iso8601,
          'primary' => false,
          'user_id' => user.id,
          'user_url' => user_url(user),
          'suspension_url' => user_email_suspension_url(user, email),
          'self_url' => user_email_url(user, email)
      end
    end
  end

  describe '#show' do
    subject(:response) { get :show, params: }

    let(:params) { {user_id: email.user_id, id: email.uuid} }

    it { is_expected.to have_http_status :ok }

    describe 'JSON' do
      subject(:json) { JSON.parse(response.body) }

      it 'is the email record' do
        expect(json).to eq \
          'id' => email.reload.uuid,
          'address' => email.address,
          'confirmed' => true,
          'confirmed_at' => nil,
          'created_at' => email.created_at.iso8601,
          'primary' => false,
          'user_id' => user.id,
          'user_url' => user_url(user),
          'suspension_url' => user_email_suspension_url(user, email),
          'self_url' => user_email_url(user, email)
      end
    end
  end

  describe '#update' do
    subject(:response) { patch :update, params: }

    let(:params) { {user_id: email.user_id, id: email.reload.uuid} }

    context 'with changed confirmation state' do
      let(:email) { create(:email, user:, confirmed: false) }
      let(:params) { {**super(), confirmed: true} }

      it { is_expected.to have_http_status :ok }

      it 'responds with appropriate Location header' do
        expect(response.headers.to_h).to include \
          'location' => user_email_url(email.reload.user, email)
      end

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        before { Timecop.freeze }

        it 'is the updated email record' do
          expect(json).to include 'id' => email.reload.uuid
          expect(json).to include 'confirmed' => true
          expect(json).to include 'confirmed_at' => Time.zone.now.iso8601
        end
      end
    end

    context 'make primary' do
      let(:old_email) { user.emails.first }
      let(:params) { {**super(), primary: 'true'} }

      context 'with unconfirmed email' do
        let(:email) { create(:email, user:, confirmed: false) }

        it 'does not set unconfirmed email as primary' do
          expect { response }.not_to change(user, :primary_email)
        end

        it { is_expected.to have_http_status :unprocessable_content }

        describe 'JSON' do
          subject(:json) { JSON.parse(response.body) }

          it 'includes primary => unconfirmed error' do
            expect(json['errors']).to include 'primary' => ['unconfirmed']
          end
        end
      end

      context 'with confirmed email' do
        let(:email) { create(:email, user:, confirmed: true) }

        it 'changes primary to new email address' do
          expect { response }.to change { user.reload.email }.to(email.address)
        end

        it 'sets primary flag on new email record' do
          expect { response }.to change { email.reload.primary }.to(true)
        end

        it 'removes primary flag on old email record' do
          expect { response }.to change { old_email.reload.primary }.to(false)
        end
      end

      context 'along confirmation' do
        let(:email) { create(:email, user:, confirmed: false) }
        let(:params) { {**super(), primary: 'true', confirmed: 'true'} }

        it 'changes primary to new email address' do
          expect { response }.to change { user.reload.email }.to(email.address)
        end
      end
    end

    context 'make unconfirmed' do
      let(:params) { {**super(), confirmed: 'false'} }

      context 'on primary address' do
        let(:email) do
          create(:email, user:, confirmed: true, primary: true)
        end

        it { is_expected.to have_http_status :unprocessable_content }

        it 'does not change the primary email record' do
          expect { response }.not_to change { email.reload.attributes }
        end

        context 'with force param' do
          let(:params) { {**super(), force: 'true'} }

          it { is_expected.to have_http_status :ok }

          it 'does change the primary email record' do
            expect { response }.to \
              change { email.reload.confirmed? }.from(true).to(false)
          end
        end
      end
    end
  end

  describe '#create' do
    subject(:response) { post :create, params: }

    let!(:user) { create(:user) }
    let(:params) { {} }

    context 'with valid params' do
      let(:params) { {address: 'test@xikolo.de', user_id: user.id} }

      it { expect { response }.to change(Email, :count).by(1) }
      it { expect { response }.to change(user.emails, :count).from(1).to(2) }

      it { is_expected.to have_http_status :created }

      it 'responds with appropriate Location header' do
        expect(response.headers.to_h).to include \
          'location' => user_email_url(user, user.emails.last)
      end

      context 'database record' do
        subject(:record) { response; user.emails.last }

        it { is_expected.not_to be_confirmed }

        describe '#address' do
          subject { super().address }

          it { is_expected.to eq 'test@xikolo.de' }
        end
      end
    end

    context 'with invalid email' do
      let(:params) { {address: 'test(at)xikoLOW', user_id: user.id} }

      it { expect { response }.not_to change(Email, :count) }
      it { expect { response }.not_to change(user.emails, :count) }

      it { is_expected.to have_http_status :unprocessable_content }

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it { is_expected.to eq('errors' => {'address' => ['is invalid']}) }
      end
    end
  end

  describe '#destroy' do
    subject(:response) { delete :destroy, params: }

    let(:params) { {user_id: user.id, id: email.uuid} }

    before { user; email }

    it { is_expected.to have_http_status :ok }

    it 'deletes email record from database' do
      expect { response }.to change(Email, :count).from(2).to(1)
    end

    context 'with primary address' do
      let(:email) { user.primary_email.reload }

      it { is_expected.to have_http_status :unprocessable_content }

      it 'does not delete database record' do
        expect { response }.not_to change(Email, :count)
      end

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it 'includes an errors message on "primary"' do
          expect(json['errors']).to include 'primary' => ['cannot delete']
        end
      end
    end
  end
end
