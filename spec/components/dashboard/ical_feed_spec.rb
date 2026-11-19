# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::IcalFeed, type: :component do
  subject(:component) { described_class.new(user:) }

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:session) { create(:'account_service/session', user: create(:'account_service/user', id: user_id)) }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }

  before do
    Stub.request(
      :account, :post, '/tokens',
      body: hash_including(user_id:)
    ).to_return Stub.json({token: 'token'})
  end

  context 'when the user does not have the ical_feed feature' do
    it 'does not render the component' do
      AccountService::Feature.find_by!(name: 'ical_feed').destroy!

      render_inline(component)

      expect(page.text).to be_empty
    end
  end

  context 'when the user has the ical_feed feature' do
    it 'renders a button to copy the iCal feed URL' do
      render_inline(component)

      expect(page).to have_text('You can subscribe to this feed by copying the iCal URL and importing it into your calendar application.')

      expect(page).to have_css("button[data-behavior='copy-to-clipboard']", visible: :all)
      expect(page).to have_css("[data-text='https://xikolo.de/ical.ical?u=1YLgUE6KPhaxfpGSZ&h=65bdb5f6011']", visible: :all)
    end
  end
end
