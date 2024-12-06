# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::UploadCertificateImageJob, type: :job do
  subject(:enqueue_job) { described_class.perform_later(enrollment.id) }

  let(:enrollment) { create(:enrollment, :proctored, user_id: '00000001-3100-4444-9999-000000000001') }

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class)
      .with(enrollment.id)
      .on_queue('default')
  end

  describe '#perform' do
    let(:smowl_registration_stub) do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/ConfirmRegistration')
        .with(body: /
          entity=SampleEntity
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
        /x)
        .to_return Stub.json({ConfirmRegistrationResponse: {ack: smowl_registration_code}})
    end
    let(:smowl_registration_code) { 0 }
    let(:smowl_image_stub) do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Getimage_jpg_Registration')
        .with(body: /
          entity=SampleEntity
          &password=samplepassword
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
        /x)
        .to_return Stub.json({
          Getimage_jpg_RegistrationResponse: {
            encoding: 'base64_encode',
            image: Base64.strict_encode64(user_image),
          },
        })
    end
    let(:user_image) { File.read('spec/support/files/proctoring/user_certificate_image.jpg') }
    let(:s3_head_stub) do
      stub_request(
        :head,
        %r{https://s3.xikolo.de/xikolo-certificate/proctoring/\w+/\w+.jpg}
      ).and_return(status: 404)
    end
    let(:s3_upload_stub) do
      stub_request(
        :put,
        %r{https://s3.xikolo.de/xikolo-certificate/proctoring/\w+/\w+.jpg}
      ).and_return(status: 200, body: '<xml></xml>')
    end

    before do
      smowl_registration_stub
      smowl_image_stub
      s3_head_stub
      s3_upload_stub
    end

    around {|example| perform_enqueued_jobs(&example) }

    it 'uploads the user certificate image to S3' do
      enqueue_job
      expect(s3_upload_stub).to have_been_requested
    end

    context 'when the user is not registered with SMOWL' do
      let(:smowl_registration_code) { -2 }

      it 'does not upload a user certificate image' do
        enqueue_job
        expect(s3_upload_stub).not_to have_been_requested
      end
    end

    context 'when the user certificate image already exists in S3' do
      let(:s3_head_stub) do
        stub_request(
          :head,
          %r{https://s3.xikolo.de/xikolo-certificate/proctoring/\w+/\w+.jpg}
        ).and_return(status: 200)
      end

      it 'does not (re-)upload the user certificate image' do
        enqueue_job
        expect(s3_upload_stub).not_to have_been_requested
      end
    end

    context 'when SMOWl responds with an error' do
      let(:smowl_image_stub) do
        stub_request(
          :post,
          'https://results-api.smowltech.net/index.php/Restv1/Getimage_jpg_Registration'
        ).to_return(
          headers: {'Content-Type' => 'application/json; charset=UTF-8'},
          status: 500,
          body: JSON.dump({})
        )
      end

      it 'raises an error to retry the job' do
        expect { enqueue_job }.to raise_error Proctoring::ServiceError
        expect(s3_upload_stub).not_to have_been_requested
      end
    end
  end
end
