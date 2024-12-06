# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionSnapshotController, type: :controller do
  describe '#create' do
    subject(:action) { post :create, params: }

    before do
      Stub.service :quiz, build(:'quiz:root')
      Stub.request(
        :quiz, :post, '/quiz_submission_snapshots'
      ).to_return snapshot_stub
    end

    let(:params) { {course_id: generate(:course_id), item_id: generate(:item_id)} }
    let(:json) { response.parsed_body }
    let(:snapshot_stub) { Stub.json(snapshot) }
    let(:snapshot_id) { SecureRandom.uuid }
    let(:snapshot) do
      {
        id: snapshot_id,
        url: "/quiz_submission_snapshots/#{snapshot_id}",
        updated_at: 'TIMESTAMP',
      }
    end

    context 'as a guest' do
      it { is_expected.to have_http_status :forbidden }
    end

    context 'when logged in' do
      before { stub_user }

      context 'when saving succeeds' do
        let(:params) { super().merge(quiz_submission_id: SecureRandom.uuid, submission:) }
        let(:submission) do
          {
            SecureRandom.uuid => [SecureRandom.uuid, SecureRandom.uuid],
            SecureRandom.uuid => SecureRandom.uuid,
          }
        end

        it 'returns new timestamp in response' do
          action

          expect(response).to have_http_status :ok
          expect(json['success']).to be true
          expect(json['timestamp']).to eq 'TIMESTAMP'
        end

        it 'passes through raw submission hash' do
          action

          expect(
            Stub.request(
              :quiz, :post, '/quiz_submission_snapshots',
              body: hash_including(
                submission:,
                quiz_submission_id: params[:quiz_submission_id]
              )
            )
          ).to have_been_requested
        end
      end

      context 'when saving the snapshot fails' do
        let(:snapshot_stub) { Stub.response(status: 422) }

        it 'responds with error information' do
          action
          expect(response).to have_http_status :service_unavailable
          expect(json['success']).to be false
        end
      end
    end
  end
end
