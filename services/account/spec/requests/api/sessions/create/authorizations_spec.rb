# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Create with User ID', type: :request do
  subject(:resource) { api.rel(:sessions).post(**payload).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:user) { create(:user) }

  let(:response) do
    resource.response
  rescue Restify::ClientError, Restify::ServerError => e
    e.response
  end

  describe 'POST /sessions' do
    let(:uid) { '1337' }
    let(:name) { 'John Doe' }
    let(:provider) { 'saml' }
    let(:email) { attributes_for(:email)[:address] }
    let(:authorization) do
      create(:authorization, user: nil, provider:, info:, uid:)
    end
    let(:payload) { {authorization: authorization.id} }

    describe 'provider with correct information' do
      let(:info) do
        {
          email:,
          name:,
        }
      end
      let(:payload) { {**super(), autocreate: true} }

      context '(welcome mail)' do
        context 'with user registration enabled' do
          before do
            create(:feature, name: 'account.registration', owner: Group.all_users)
          end

          it 'triggers a welcome mail' do
            # first message published triggers welcome mail
            expect(Msgr).to receive(:publish).with(
              anything,
              to: 'xikolo.web.account.sign_up'
            )

            # "drain" the other msgr messages published
            expect(Msgr).to receive(:publish).at_least(1).time

            resource
          end
        end

        it 'does not trigger a welcome mail' do
          expect(Msgr).not_to receive(:publish).with(
            anything,
            to: 'xikolo.web.account.sign_up'
          )

          resource
        end
      end
    end

    describe 'provider with missing information' do
      let(:info) do
        {
          email:,
        }
      end
      let(:payload) { {**super(), autocreate: true} }

      it 'does not create new user record' do
        expect { response }.not_to change(User, :count)
      end

      it 'does not create a new session' do
        expect { response }.not_to change(Session, :count)
      end

      it 'does not assigns the authorization to the existing user' do
        expect { response }.not_to(change { authorization.reload.user_id })
      end

      it 'responds with a unprocessable entity (422) status code' do
        expect(response).to respond_with :unprocessable_content
      end

      describe 'payload error messages' do
        it do
          expect(response.decoded_body).to match(
            'errors' => {
              'authorization' => ['invalid_information'],
              'details' => [{
                'full_name' => ["can't be blank"],
              }],
            }
          )
        end
      end
    end
  end
end
