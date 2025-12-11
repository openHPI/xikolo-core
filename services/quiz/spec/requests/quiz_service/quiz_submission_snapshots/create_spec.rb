# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz Submission Snapshots: Create', type: :request do
  subject(:creation) { api.rel(:quiz_submission_snapshots).post(payload).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }

  let(:payload) { {quiz_submission_id: submission.id} }
  let!(:submission) { create(:'quiz_service/quiz_submission') }

  it { is_expected.to respond_with :created }

  it 'stores a new snapshot' do
    expect { creation }.to change(QuizService::QuizSubmissionSnapshot, :count).from(0).to(1)
  end

  context 'with data hash' do
    let(:payload) do
      {
        **super(),
        submission: {
          '00000000-0000-4444-9999-000000000001' => ['00000000-0000-4444-9999-000000000001'],
          '00000000-0000-4444-9999-000000000002' => '00000000-0000-4444-9999-000000000003',
        },
      }
    end

    it { is_expected.to respond_with :created }

    it 'stores serialized data' do
      creation
      expect(JSON.parse(QuizService::QuizSubmissionSnapshot.first.read_attribute_before_type_cast(:data))).to eq payload[:submission]
    end

    it 'returns deserialized data' do
      expect(creation['data']).to eq QuizService::QuizSubmissionSnapshot.first.data
    end

    it 'returns the loaded_data' do
      expect(creation['loaded_data']).to eq payload[:submission]
    end
  end

  context 'second creation for same quiz submission' do
    let!(:snapshot) { submission.create_quiz_submission_snapshot! }

    it { is_expected.to respond_with :created }

    it 'does not create a new snapshot' do
      expect { creation }.not_to change(QuizService::QuizSubmissionSnapshot, :count)
    end

    it 'returns the initial snapshot' do
      expect(creation['id']).to eq snapshot.id
    end

    context 'with data hash' do
      let(:payload) do
        {
          **super(),
          submission: {
            '00000000-0000-4444-9999-000000000001' => ['00000000-0000-4444-9999-000000000001'],
            '00000000-0000-4444-9999-000000000002' => '00000000-0000-4444-9999-000000000003',
            '00000000-0000-4444-9999-000000000004' => '00000000-0000-4444-9999-000000000005',
          },
        }
      end

      it 'changes the data attribute' do
        expect { creation }.to \
          change { snapshot.reload.data }
          .from(nil)
          .to(payload[:submission])
      end
    end
  end
end
