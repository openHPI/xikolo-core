# frozen_string_literal: true

require 'spec_helper'

describe 'API v2 version expiry & negotiation' do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  describe 'GET /' do
    subject(:api_request) { get '/v2/', nil, env_hash }

    let(:env_hash) { {} }

    # Stop the time so that we can properly test version expiry by date
    around do |example|
      Timecop.freeze(DateTime.parse('2017-08-10 11:00:00')) do
        example.run
      end
    end

    before do
      # Stub the supported versions so that this test does not have
      # to change when the actually supported versions change
      allow(Xikolo::API).to receive(:supported_versions).and_return([
        Xikolo::Versioning::Version.new('2.3', expire_on: Date.new(2017, 8, 5)),
        Xikolo::Versioning::Version.new('3.1', expire_on: Date.new(2017, 8, 15)),
        Xikolo::Versioning::Version.new('4.7'),
      ])
    end

    context 'without request headers' do
      it 'responds with the current version' do
        api_request
        expect(last_response.content_type).to eq 'application/vnd.api+json; xikolo-version=4.7'
      end
    end

    context 'with Accept request header' do
      let(:env_hash) { super().merge('HTTP_ACCEPT' => "application/vnd.api+json; xikolo-version=#{requested_version}") }

      context 'requesting current version' do
        let(:requested_version) { '4' }

        it 'responds with the current version' do
          api_request
          expect(last_response.content_type).to eq 'application/vnd.api+json; xikolo-version=4.7'
        end
      end

      context 'requesting old, but supported version' do
        let(:requested_version) { '3' }

        it 'responds with the requested, older version' do
          api_request
          expect(last_response.content_type).to eq 'application/vnd.api+json; xikolo-version=3.1'
        end

        it 'lists the expiration date in the header' do
          api_request
          expect(last_response.headers['Sunset']).to eq 'Tue, 15 Aug 2017 00:00:00 GMT'
          # @deprecated
          expect(last_response.headers['X-Api-Version-Expiration-Date']).to eq 'Tue, 15 Aug 2017 00:00:00 GMT'
        end
      end

      context 'requesting old, but expired version' do
        let(:requested_version) { '2' }

        it 'responds with 406 Not Acceptable' do
          api_request
          expect(last_response.status).to eq 406
        end
      end

      context 'requesting old, forgotten version' do
        let(:requested_version) { '1' }

        it 'responds with 406 Not Acceptable' do
          api_request
          expect(last_response.status).to eq 406
        end
      end

      context 'with mobile app sunset' do
        before do
          xi_config <<~YML
            api:
              blocked_course_ids: []
              mobile_app_sunset_date: #{sunset_date}
          YML
        end

        context 'in the future' do
          let(:sunset_date) { 5.days.from_now }
          let(:requested_version) { '4.7' }

          # The sunset date determines the expiry of the API
          # even when no expiry date is set.
          it 'has not yet expired but will expire' do
            api_request
            expect(last_response.status).to eq 200
            expect(last_response.headers['Sunset']).to eq 'Tue, 15 Aug 2017 11:00:00 GMT'
            # @deprecated
            expect(last_response.headers['X-Api-Version-Expiration-Date']).to eq 'Tue, 15 Aug 2017 11:00:00 GMT'
          end
        end

        context 'in the past' do
          let(:sunset_date) { 5.days.ago }
          let(:requested_version) { '4.7' }

          # With the sunset date, the current API version shall not expire
          # allowing the apps still to connect to the API after the sunset date.
          it 'has not yet expired but will expire' do
            api_request
            expect(last_response.status).to eq 200
            expect(last_response.headers['Sunset']).to eq 'Sat, 05 Aug 2017 11:00:00 GMT'
            # @deprecated
            expect(last_response.headers['X-Api-Version-Expiration-Date']).to eq 'Sat, 05 Aug 2017 11:00:00 GMT'
          end
        end
      end
    end
  end
end
