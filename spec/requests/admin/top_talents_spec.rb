# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: TopTalents', type: :request do
  let(:user) { create(:'account_service/user') }

  def sign_in_with_delete_permission(user)
    role = create(:'account_service/role', permissions: ['account.user.delete'])
    create(:'account_service/grant', principal: user, role:)
    sign_in(user:)
  end

  describe '#create' do
    context 'without permission' do
      before { sign_in(user:) }

      it 'redirects to root' do
        post user_top_talents_path(user)
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      before { sign_in_with_delete_permission(user) }

      it 'marks the user as top talent and redirects back' do
        expect { post user_top_talents_path(user) }
          .to change { user.reload.top_talent? }.from(false).to(true)

        expect(response).to redirect_to user_path(user.id)
        expect(flash[:success]).to include I18n.t(:'flash.success.user_marked_top_talent')
      end

      it 'is idempotent' do
        post user_top_talents_path(user)

        expect { post user_top_talents_path(user) }.not_to change { UserTopTalent.where(user:).count }
      end
    end
  end

  describe '#destroy' do
    before { user.grant_top_talent!(source: 'admin') }

    context 'without permission' do
      before { sign_in(user:) }

      it 'redirects to root' do
        delete user_top_talents_path(user)
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      before { sign_in_with_delete_permission(user) }

      it 'unmarks the user but keeps the record and redirects back' do
        expect { delete user_top_talents_path(user) }.to change { user.reload.top_talent? }.from(true).to(false)

        expect(UserTopTalent.where(user:).count).to eq 1
        expect(response).to redirect_to user_path(user.id)
        expect(flash[:success]).to include I18n.t(:'flash.success.user_unmarked_top_talent')
      end
    end
  end
end
