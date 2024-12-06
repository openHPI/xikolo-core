# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::StoreSubmissionResultsJob, type: :job do
  subject(:enqueue_job) { described_class.perform_later(submission_id) }

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:quiz_id) { generate(:quiz_id) }
  let(:submission_id) { SecureRandom.uuid }
  let(:smowl_quiz_id) { "#{UUID4(quiz_id).to_s(format: :base62)}_#{UUID4(submission_id).to_s(format: :base62)}" }

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class)
      .with(submission_id)
      .on_queue('default')
  end

  describe '#perform' do
    let(:smowl_results_stub) do
      stub_request(
        :post,
        'https://results-api.smowltech.net/index.php/Restv1/Get_Results_Array'
      ).with(
        body: /
          entity=SampleEntity
          &password=samplepassword
          &modality=quiz
          &idActivity=#{smowl_quiz_id}
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
        /x
      ).to_return(
        headers: {'Content-Type' => 'application/json; charset=UTF-8'},
        status: 200,
        body: JSON.dump({
          Get_Results_ArrayResponse: {
            results: {
              CORRECTUSER: 6,
              NOBODYINTHEPICTURE: 0,
              WRONGUSER: 0,
              SEVERALPEOPLE: 0,
              WEBCAMCOVERED: 2,
              INVALIDCONDITIONS: 0,
              WEBCAMDISCARTED: 0,
              NOTALLOWEDELEMENT: 0,
              NOCAM: 0,
              OTHERAPPBLOCKINGTHECAM: 0,
              NOTSUPPORTEDBROWSER: 0,
              OTHERTAB: 0,
              EMPTYIMAGE: 0,
              SUSPICIOUS: 0,
            },
          },
        })
      )
    end
    let(:submission_id) { submission['id'] }
    let(:submission) do
      build(:'quiz:submission',
        :proctoring_smowl_v2_pending,
        user_id:,
        quiz_id:)
    end
    let(:update_submission_stub) do
      Stub.request(:quiz, :patch, "/quiz_submissions/#{submission_id}")
        .to_return Stub.response(status: 201)
    end
    let(:results_ready) { true }

    before do
      xi_config <<~YML
        proctoring_smowl_endpoints:
          api_base: "https://results-api.smowltech.net/index.php/Restv1/{function}"
      YML

      create(:course, :active, :offers_proctoring, id: submission['course_id'])

      Stub.service(:quiz, build(:'quiz:root'))
      Stub.request(:quiz, :get, "/quiz_submissions/#{submission_id}")
        .to_return Stub.json(submission)
      update_submission_stub
      smowl_results_stub

      stub_request(
        :post,
        'https://results-api.smowltech.net/index.php/Restv1/Results_Ready_Activity'
      ).with(
        body: /
          entity=SampleEntity
          &password=samplepassword
          &modality=quiz
          &idActivity=#{smowl_quiz_id}
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
        /x
      ).to_return(
        headers: {'Content-Type' => 'application/json; charset=UTF-8'},
        status: 200,
        body: JSON.dump({
          Results_Ready_ActivityResponse: {ack: results_ready},
        })
      )
    end

    around {|example| perform_enqueued_jobs(&example) }

    it 'updates the quiz submission with the results' do
      enqueue_job
      expect(
        update_submission_stub.with(body: {
          'vendor_data' => {
            'proctoring' => 'smowl_v2',
            'proctoring_smowl_v2' => {
              'nobodyinthepicture' => 0,
              'wronguser' => 0,
              'severalpeople' => 0,
              'webcamcovered' => 2,
              'invalidconditions' => 0,
              'webcamdiscarted' => 0,
              'notallowedelement' => 0,
              'nocam' => 0,
              'otherappblockingthecam' => 0,
              'notsupportedbrowser' => 0,
              'othertab' => 0,
              'emptyimage' => 0,
              'suspicious' => 0,
            },
          },
        })
      ).to have_been_requested
    end

    context 'with proctoring results not yet ready for the submission' do
      let(:results_ready) { false }
      let(:smowl_results_stub) do
        stub_request(
          :post,
          'https://results-api.smowltech.net/index.php/Restv1/Get_Results_Array'
        ).with(
          body: /
          entity=SampleEntity
          &password=samplepassword
          &modality=quiz
          &idActivity=#{smowl_quiz_id}
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
        /x
        ).to_return(
          headers: {'Content-Type' => 'application/json; charset=UTF-8'},
          status: 200,
          body: JSON.dump({
            Get_Results_ArrayResponse: {
              results: {
                CORRECTUSER: nil,
                NOBODYINTHEPICTURE: nil,
                WRONGUSER: nil,
                SEVERALPEOPLE: nil,
                WEBCAMCOVERED: nil,
                INVALIDCONDITIONS: nil,
                WEBCAMDISCARTED: nil,
                NOTALLOWEDELEMENT: nil,
                NOCAM: nil,
                OTHERAPPBLOCKINGTHECAM: nil,
                NOTSUPPORTEDBROWSER: nil,
                OTHERTAB: nil,
                EMPTYIMAGE: nil,
                SUSPICIOUS: nil,
              },
            },
          })
        )
      end

      it 'does not store pending results in the vendor data and plans a retry' do
        expect { enqueue_job }.to raise_error(ApplicationJob::ExpectedRetry, 'Proctoring results not ready')
        expect(update_submission_stub).not_to have_been_requested
      end
    end

    context 'with existing submission vendor data' do
      let(:submission) do
        build(
          :'quiz:submission',
          :proctoring_smowl_v1_passed_with_violations,
          user_id:,
          quiz_id:
        )
      end

      it 'does not overwrite other vendor data' do
        enqueue_job
        expect(
          update_submission_stub.with(body: {
            'vendor_data' => {
              'proctoring_smowl' => {
                'black' => '1',
                'cheat' => '0',
                'covered' => '0',
                'discarted' => '2',
                'morepeople' => '0',
                'nobody' => '0',
                'othertab' => '0',
                'wrongimage' => '0',
                'wronguser' => '0',
              },
              'proctoring_smowl_v2' => {
                'nobodyinthepicture' => 0,
                'wronguser' => 0,
                'severalpeople' => 0,
                'webcamcovered' => 2,
                'invalidconditions' => 0,
                'webcamdiscarted' => 0,
                'notallowedelement' => 0,
                'nocam' => 0,
                'otherappblockingthecam' => 0,
                'notsupportedbrowser' => 0,
                'othertab' => 0,
                'emptyimage' => 0,
                'suspicious' => 0,
              },
            },
          })
        ).to have_been_requested
      end
    end

    context 'with existing submission vendor data for the requested vendor data version' do
      let(:submission) do
        build(
          :'quiz:submission',
          :proctoring_smowl_v2_passed_with_violations,
          user_id:,
          quiz_id:
        )
      end

      it 'does not overwrite existing vendor data' do
        enqueue_job
        expect(update_submission_stub).not_to have_been_requested
      end
    end

    context 'when SMOWl responds with an error' do
      let(:smowl_results_stub) do
        stub_request(
          :post,
          'https://results-api.smowltech.net/index.php/Restv1/Get_Results_Array'
        ).to_return(
          headers: {'Content-Type' => 'application/json; charset=UTF-8'},
          status: 500,
          body: JSON.dump({})
        )
      end

      it 'raises an error to retry the job' do
        expect { enqueue_job }.to raise_error Proctoring::ServiceError
        expect(update_submission_stub).not_to have_been_requested
      end
    end
  end
end
