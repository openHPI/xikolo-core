# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Tracking::TrackingEvents do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:env) do
    {
      'HTTP_ACCEPT' => 'application/json',
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'rack.session' => {id: stub_session_id},
    }
  end

  before do
    Stub.service(:account, build(:'account:root'))

    api_stub_user
  end

  context 'POST tracking event' do
    subject(:response) { post '/v2/tracking-events', payload.to_json, env }

    context 'a single event' do
      let(:payload) do
        {
          data: {
            type: 'tracking-events',
            id: nil,
            attributes: {
              context: {},
              user: {
                uuid: '6',
              },
              verb: {
                type: 'POSTED',
              },
              resource: {
                type: 'b',
                uuid: 'foobar',
              },
            },
          },
        }
      end

      it 'sends the event data to lanalytics' do
        expect(Msgr).to receive(:publish).once.with(
          hash_including('verb' => {'type' => 'POSTED'}),
          hash_including(to: 'xikolo.web.exp_event.create')
        )
        response
      end

      describe '(data)' do
        subject(:json) { JSON.parse(response.body)['data'] }

        it 'has [id] set' do
          expect(json['id'].present?).to be true
        end
      end
    end

    context 'multiple events' do
      let(:payload) do
        {
          data: [
            {
              type: 'tracking-events',
              id: nil,
              attributes: {
                context: {},
                user: {
                  uuid: '6',
                },
                verb: {
                  type: 'POSTED',
                },
                resource: {
                  type: 'b',
                  uuid: 'foobar',
                },
              },
            },
            {
              type: 'tracking-events',
              id: nil,
              attributes: {
                context: {},
                user: {
                  uuid: '3',
                },
                verb: {
                  type: 'ENROLLED',
                },
                resource: {
                  type: 'c',
                  uuid: 'platform',
                },
              },
            },
          ],
        }
      end

      it 'sends the event data to lanalytics' do
        expect(Msgr).to receive(:publish).once.with(
          hash_including('verb' => {'type' => 'POSTED'}),
          hash_including(to: 'xikolo.web.exp_event.create')
        )
        expect(Msgr).to receive(:publish).once.with(
          hash_including('verb' => {'type' => 'ENROLLED'}),
          hash_including(to: 'xikolo.web.exp_event.create')
        )
        response
      end

      describe '(data)' do
        subject { JSON.parse(response.body)['data'] }

        it { is_expected.to be_an Array }
      end
    end

    context 'without user' do
      let(:payload) do
        {
          data: {
            type: 'tracking-events',
            id: nil,
            attributes: {
              context: {},
              verb: {
                type: 'POSTED',
              },
              resource: {
                type: 'b',
                uuid: 'foobar',
              },
            },
          },
        }
      end

      it 'responds error code' do
        expect(response.status).to eq 422
      end
    end

    context 'without resource' do
      let(:payload) do
        {
          data: {
            type: 'tracking-events',
            id: nil,
            attributes: {
              context: {},
              user: {
                uuid: '6',
              },
              verb: {
                type: 'POSTED',
              },
            },
          },
        }
      end

      it 'responds error code' do
        expect(response.status).to eq 422
      end
    end

    context 'without verb' do
      let(:payload) do
        {
          data: {
            type: 'tracking-events',
            id: nil,
            attributes: {
              context: {},
              user: {
                uuid: '6',
              },
              resource: {
                type: 'b',
                uuid: 'foobar',
              },
            },
          },
        }
      end

      it 'responds error code' do
        expect(response.status).to eq 422
      end
    end
  end
end
