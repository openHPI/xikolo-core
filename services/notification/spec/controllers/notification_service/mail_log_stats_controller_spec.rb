# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::MailLogStatsController, type: :controller do
  subject { JSON[response.body].with_indifferent_access }

  include_context 'notification_service controller'

  let(:params) { {} }
  let(:old_ts) { 5.days.ago }
  let(:medium_ts) { 2.days.ago }
  let(:new_ts)  { 1.day.ago }
  let(:news_id) { '00000001-aaaa-4444-9999-000000000001' }

  before do
    create(:'notification_service/mail_log', news_id:, created_at: old_ts)
    create(:'notification_service/mail_log', news_id:, created_at: medium_ts)
    create(:'notification_service/mail_log', news_id:, created_at: new_ts)
    create(:'notification_service/mail_log', news_id:, created_at: new_ts, state: 'error')
    create(:'notification_service/mail_log', news_id:, created_at: new_ts, state: 'error')
    create(:'notification_service/mail_log', news_id:, created_at: new_ts, state: 'disabled')
  end

  describe 'GET show' do
    subject { JSON[response.body].with_indifferent_access }

    let(:action) { -> { get :show, params: } }
    let(:params) { {news_id:} }

    before do
      action.call
    end

    it 'returns a valid http response' do
      expect(response).to have_http_status :ok
    end

    its(['count']) { is_expected.to eq 6 }
    its(['success_count']) { is_expected.to eq 3 }
    its(['error_count']) { is_expected.to eq 2 }
    its(['disabled_count']) { is_expected.to eq 1 }
    its(['unique_count']) { is_expected.to eq 1 } # by user
    its(['oldest'])  { is_expected.to eq old_ts.iso8601 }
    its(['newest'])  { is_expected.to eq new_ts.iso8601 }
  end
end
