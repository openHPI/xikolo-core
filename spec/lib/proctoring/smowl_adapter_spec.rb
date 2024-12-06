# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::SmowlAdapter do
  subject(:proctoring) { described_class.new(course) }

  let(:course) { build(:course, course_code: 'short_course_id') }

  describe '#registration_status' do
    subject(:registration_status) { proctoring.registration_status(user_id) }

    let(:user_id) { '00000001-3100-4444-9999-000000000001' }
    let(:pseudonymized_user_id) { '35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d' }
    let(:smowl_response) do
      Stub.json({ConfirmRegistrationResponse: {ack: smowl_registration_code}})
    end
    let(:smowl_registration_code) { 0 }

    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/ConfirmRegistration')
        .with(body: /entity=SampleEntity&idUser=#{pseudonymized_user_id}/)
        .to_return smowl_response
    end

    it 'indicates a completed registration with SMOWL' do
      expect(registration_status).to be_available
      expect(registration_status.status).to eq :complete
    end

    context 'when not registered with SMOWL' do
      let(:smowl_registration_code) { -2 }

      it 'user registration is required' do
        expect(registration_status).to be_available
        expect(registration_status).not_to be_complete
        expect(registration_status).not_to be_pending
        expect(registration_status).to be_required
        expect(registration_status.status).to eq :required
      end
    end

    context 'with not yet completed registration with SMOWL' do
      let(:smowl_registration_code) { -1 }

      it 'user registration is pending' do
        expect(registration_status).to be_available
        expect(registration_status).not_to be_complete
        expect(registration_status).to be_pending
        expect(registration_status).not_to be_required
        expect(registration_status.status).to eq :pending
      end
    end

    context 'with not accepted terms when registering with SMOWL' do
      let(:smowl_registration_code) { -3 }

      it 'user registration is required' do
        expect(registration_status).to be_available
        expect(registration_status).not_to be_complete
        expect(registration_status).not_to be_pending
        expect(registration_status).to be_required
        expect(registration_status.status).to eq :required
      end
    end

    context 'with an error response' do
      let(:smowl_response) { Stub.json({}, status: 500) }

      it 'cannot determine the registration status' do
        # It is important to expose this (temporary) state, so that the
        # "unavailable" status can be communicated correctly to the user.
        expect(registration_status).not_to be_available
      end
    end
  end

  describe '#passed?' do
    subject(:passed) { proctoring.passed?(user) }

    let(:user) { Struct.new(:id).new(user_id) }
    let(:user_id) { '00000001-3100-4444-9999-000000000001' }
    let(:smowl_response) { Stub.json({Passed_Fail_CourseResponse: {ack: true}}) }

    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Passed_Fail_Course')
        .with(body: /
          entity=SampleEntity
          &password=samplepassword
          &idUser=35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d
          &idCourse=short_course_id
          &alarm_type=[0,1]
          &a1_Nobody=\d
          &a2_IncorrectUser=\d
          &a3_MorePeople=\d
          &a4_Covered=\d
          &a5_ImagNotValid=\d
          &a6_Discarted=\d
          &a7_NotAllowedElements=\d
          &a8_Tab=\d
          &a9_ConfigProblem=\d
          &a10_NotSupportedBrowser=\d
          &a11_Nocam=\d
          &a12_Otherapp=\d
          &a14_CorrectImages=\d
        /x).to_return(smowl_response)
    end

    it { is_expected.to be_truthy }

    context 'with an error response' do
      let(:smowl_response) { Stub.json({}, status: 500) }

      it 'raises an exception' do
        expect { passed }.to raise_error(Proctoring::ServiceError)
      end
    end
  end
end
