# frozen_string_literal: true

require 'spec_helper'

describe 'Users', type: :request do
  let(:user) { create(:'account_service/user') }
  let(:html) { Capybara.string(response.body) }
  let(:top_talents_url) { user_top_talents_path(user) }

  def sign_in_with_delete_permission(user)
    role = create(:'account_service/role', permissions: ['account.user.delete'])
    create(:'account_service/grant', principal: user, role:)
    sign_in(user:)
  end

  describe '#show' do
    subject(:show) { get user_path(user) }

    before do
      Stub.request(:account, :get, "/users/#{user.id}/preferences")
        .to_return Stub.json({properties: {}})
    end

    context 'as a non-admin user' do
      before { sign_in(user: user) }

      it 'responds with ok' do
        show
        expect(response).to have_http_status(:ok)
      end

      context 'when the user is top talent' do
        before { user.grant_top_talent!(source: 'admin') }

        it 'does not show the top talent badge' do
          show
          expect(response.body).not_to include I18n.t('users.show.top_talent')
        end
      end
    end

    context 'as an admin' do
      before { sign_in_with_delete_permission(user) }

      context 'when the user is not top talent' do
        it 'renders the flag toggle' do
          show
          expect(html).to have_css("a[data-method='post'][href='#{top_talents_url}']")
          expect(html).to have_no_css("a[data-method='delete'][href='#{top_talents_url}']")
        end
      end

      context 'when the user is top talent' do
        before { user.grant_top_talent!(source: 'admin') }

        it 'renders the unflag toggle and the badge' do
          show
          expect(html).to have_css("a[data-method='delete'][href='#{top_talents_url}']")
          expect(html).to have_no_css("a[data-method='post'][href='#{top_talents_url}']")
          expect(html).to have_css('.x-badge', text: I18n.t('users.show.top_talent'))
        end
      end
    end
  end

  describe '#destroy' do
    subject(:destroy) { delete user_path(user) }

    before do
      Stub.request(:account, :delete, "/users/#{user.id}")
        .to_return status: 200, headers: {}
    end

    context 'as current_user' do
      before { sign_in(user: user) }

      it { is_expected.to redirect_to root_url }

      it 'resets the session' do
        destroy
        expect(session['id']).to eq('anonymous')
      end

      it 'asks xi-account to delete the session' do
        expect { destroy }.to change { user.sessions.count }.to(0)
      end
    end
  end
end
