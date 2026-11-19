# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionSnapshotController, type: :controller do
  describe '#create' do
    subject(:action) { post :create, params: }

    let(:params) { {course_id: generate(:course_id), item_id: generate(:item_id)} }
    let(:json) { response.parsed_body }

    context 'as a guest' do
      it { is_expected.to have_http_status :forbidden }
    end

    context 'when logged in' do
      before { sign_in }

      context 'when saving succeeds' do
        let!(:submission_record) { create(:'quiz_service/quiz_submission') }
        let(:params) { super().merge(quiz_submission_id: submission_record.id, submission:) }
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
          expect(json['timestamp']).to eq submission_record.reload.quiz_submission_snapshot.updated_at.as_json
          expect(submission_record.quiz_submission_snapshot.data).to eq submission
        end

        it 'stores the raw submission hash' do
          action

          expect(submission_record.reload.quiz_submission_snapshot.data).to eq submission
        end
      end

      context 'when saving the snapshot fails' do
        let(:params) { super().merge(quiz_submission_id: SecureRandom.uuid) }

        it 'responds with error information' do
          action
          expect(response).to have_http_status :service_unavailable
          expect(json['success']).to be false
        end
      end
    end
  end
end
