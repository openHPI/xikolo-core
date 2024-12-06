# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionSnapshotsController, type: :controller do
  let(:quiz_submission_snapshot) { create(:quiz_submission_snapshot) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:action) { get :index }

    shared_examples_for 'a successful index call' do
      it { is_expected.to be_successful }

      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to be_a Array }
      end
    end

    context 'should answer with a list' do
      before { quiz_submission_snapshot }

      it_behaves_like 'a successful index call'
      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to have(1).item }
      end
    end

    context 'should answer with quiz_submission_snapshot objects' do
      before { quiz_submission_snapshot }

      it_behaves_like 'a successful index call'
      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to be_a Array }

        its(:first) { is_expected.to eq QuizSubmissionSnapshotDecorator.new(quiz_submission_snapshot).as_json(api_version: 1) }
      end
    end
  end

  describe '#show' do
    it 'responds with 200 Ok' do
      get :show, params: {id: quiz_submission_snapshot.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with quiz_submission_snapshot object' do
      get :show, params: {id: quiz_submission_snapshot.id}
      expect(json).to eq(QuizSubmissionSnapshotDecorator.new(quiz_submission_snapshot).as_json(api_version: 1).stringify_keys)
    end
  end

  describe '#destroy' do
    subject(:action) { delete :destroy, params: {id: quiz_submission_snapshot.id} }

    it 'responds with 204 No Content' do
      action
      expect(response).to have_http_status :no_content
    end

    it 'removes a quiz_submission_snapshot' do
      quiz_submission_snapshot
      expect { action }.to change(QuizSubmissionSnapshot, :count).from(1).to(0)
    end
  end
end
