# frozen_string_literal: true

require 'spec_helper'
require 'middleware/news_tracker'

require 'rack'

describe Middleware::NewsTracker do
  subject(:middleware) { described_class.new rack_app }

  let(:rack_app) { ->(_env) { [200, {'Content-Type' => 'text/plain'}, ['OK']] } }

  describe '#call' do
    subject(:response) { middleware.call env }

    let(:env) { Rack::MockRequest.env_for("https://example.de#{query}") }

    context 'without tracking parameters' do
      let(:query) { '' }

      it { is_expected.to eq [200, {'Content-Type' => 'text/plain'}, ['OK']] }
    end

    context 'with tracking parameters' do
      before do
        Stub.service(
          :news,
          visits_url: '/visits'
        )
      end

      let!(:mark_announcement_as_read) do
        Stub.request(
          :news, :post, '/visits',
          body: {user_id:, announcement_id:}
        ).to_return Stub.json({})
      end
      let(:query) { "?tracking_type=news&tracking_user=#{user_id}&tracking_id=#{announcement_id}" }

      context 'that are invalid' do
        let(:user_id) { 'abc' }
        let(:announcement_id) { 'def' }

        it { is_expected.to eq [200, {'Content-Type' => 'text/plain'}, ['OK']] }

        it 'does not try to mark the announcement as read' do
          response
          expect(mark_announcement_as_read).not_to have_been_requested
        end
      end

      context 'that are valid' do
        let(:user_id) { SecureRandom.uuid }
        let(:announcement_id) { SecureRandom.uuid }

        it { is_expected.to eq [200, {'Content-Type' => 'text/plain'}, ['OK']] }

        it 'marks the announcement as read' do
          response
          expect(mark_announcement_as_read).to have_been_requested
        end
      end
    end
  end
end
