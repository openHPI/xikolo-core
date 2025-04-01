# frozen_string_literal: true

require 'spec_helper'

describe Quiz::Submission, '#proctoring' do
  subject(:proctoring) { Quiz::Submission.from_restify(submission).proctoring }

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
