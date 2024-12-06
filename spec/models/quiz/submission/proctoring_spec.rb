# frozen_string_literal: true

require 'spec_helper'

describe Quiz::Submission, '#proctoring' do
  subject(:proctoring) { Quiz::Submission.from_restify(submission).proctoring }

  describe '#vendor_cam_url' do
    subject(:cam_url) { proctoring.vendor_cam_url }

    let(:user_id) { '00000001-3100-4444-9999-000000000001' }
    let(:pseudonymized_user_id) do
      '35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d'
    end
    let(:submission) do
      build(:'quiz:submission', :proctoring_smowl_v2_passed, user_id:)
    end
    let(:activity_id) do
      "#{UUID4(submission['quiz_id']).to_s(format: :base62)}_#{UUID4(submission['id']).to_s(format: :base62)}"
    end

    before do
      create(:course, :active, :offers_proctoring,
        id: submission['course_id'],
        course_code: 'the-course')
    end

    it do
      expect(cam_url).to eq(
        'https://swl.smowltech.net/monitor/controller.php?' \
        'entity_Name=SampleEntity' \
        '&swlLicenseKey=samplekey' \
        '&modality_ModalityName=quiz' \
        "&course_CourseName=#{activity_id}" \
        '&course_Container=the-course' \
        "&user_idUser=#{pseudonymized_user_id}" \
        '&lang=en' \
        '&type=0' \
        '&Course_link=https%3A%2F%2Fxikolo.de%2Fcourses%2Fthe-course'
      )
    end
  end

  describe '#results' do
    subject(:results) { proctoring.results }

    before { create(:course, :active, :offers_proctoring, id: submission['course_id']) }

    context 'user passed proctoring (SMOWL v1)' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v1_passed) }

      it 'does not report any violations' do
        expect(results.issues?).to be false
      end
    end

    context 'user passed proctoring (SMOWL v1) with a few violations' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v1_passed_with_violations) }

      it 'reports the existence of violations' do
        expect(results.issues?).to be true
      end
    end

    context 'user failed proctoring (SMOWL v1) b/c of too many violations' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v1_failed) }

      it 'reports the existence of violations' do
        expect(results.issues?).to be true
      end
    end

    context 'user passed proctoring (SMOWL v2)' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v2_passed) }

      it 'does not report any violations' do
        expect(results.issues?).to be false
      end
    end

    context 'user passed proctoring (SMOWL v2) with a few violations' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v2_passed_with_violations) }

      it 'reports the existence of violations' do
        expect(results.issues?).to be true
      end
    end

    context 'user failed proctoring (SMOWL v2) b/c of too many violations' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v2_failed) }

      it 'reports the existence of violations' do
        expect(results.issues?).to be true
      end
    end

    context 'proctoring results have not yet been processed' do
      let(:submission) { build(:'quiz:submission', :proctoring_smowl_v2_pending) }

      it 'does not report any violations' do
        expect(results.issues?).to be false
      end
    end
  end
end
