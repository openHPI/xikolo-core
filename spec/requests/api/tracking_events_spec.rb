# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API: Tracking events', type: :request do
  let(:headers) { {'Content-Type': 'application/json'} }

  describe 'POST tracking event' do
    subject(:call) do
      post('/api/tracking-events', params: payload.to_json, headers:)
    end

    context 'no event' do
      let(:payload) do
        {events: []}
      end

      it 'sends nothing to lanalytics' do
        expect(Msgr).not_to receive(:publish)
        call
      end

      it 'responds with 204 No Content' do
        call
        expect(response).to have_http_status :no_content
      end
    end

    context 'an invalid event' do
      let(:payload) do
        {events: [{}]}
      end

      it 'sends nothing to lanalytics' do
        expect(Msgr).not_to receive(:publish)
        call
      end

      it 'responds with 422 Unprocessable Content' do
        call
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context 'a single event' do
      let(:payload) do
        {
          events: [{
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
            context: {b: 2, c: nil},
            result: {a: [1]},
            timestamp: '1990-12-24T13:37:00',
          }],
        }
      end

      it 'sends the enriched event to lanalytics' do
        expect(Msgr).to receive(:publish).once do |*args|
          expect(args.size).to eq 2

          args[0].tap do |payload|
            # Test the exact and full payload send to msgr including
            # enriched fields. This fails when unexpected keys are
            # present.
            expect(payload).to eq({
              'user' => {'uuid' => '6'},
              'verb' => {'type' => 'POSTED'},
              'resource' => {'type' => 'b', 'uuid' => 'foobar'},
              'in_context' => {'b' => 2, 'c' => nil, 'user_ip' => '127.0.0.1'},
              'with_result' => {'a' => [1]},
              'timestamp' => '1990-12-24T13:37:00',
            })
          end

          args[1].tap do |options|
            expect(options).to eq({
              to: 'xikolo.web.exp_event.create',
            })
          end
        end

        call
        expect(response).to have_http_status :no_content
      end
    end

    context 'multiple events' do
      let(:payload) do
        {
          events: [
            {
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
            {
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
          ],
        }
      end

      it 'sends all events to lanalytics' do
        expect(Msgr).to receive(:publish).once.with(
          hash_including('verb' => {'type' => 'POSTED'}),
          hash_including(to: 'xikolo.web.exp_event.create')
        )
        expect(Msgr).to receive(:publish).once.with(
          hash_including('verb' => {'type' => 'ENROLLED'}),
          hash_including(to: 'xikolo.web.exp_event.create')
        )

        call
        expect(response).to have_http_status :no_content
      end
    end
  end
end
