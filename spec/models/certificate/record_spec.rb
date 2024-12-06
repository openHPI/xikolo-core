# frozen_string_literal: true

require 'spec_helper'

describe Certificate::Record, type: :model do
  subject(:record) do
    described_class.new(
      user:,
      course:,
      template:,
      type: 'RecordOfAchievement'
    )
  end

  let(:template) { create(:certificate_template, course:) }
  let(:user) { create(:user) }
  let(:course) { create(:course, records_released:) }
  let(:records_released) { true }

  let(:enrollment_stub) do
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
    ).to_return enrollments
  end
  let(:enrollments) do
    Stub.json(
      build_list(
        :'course:enrollment', 1, :with_learning_evaluation,
        course_id: course.id,
        user_id: user.id
      )
    )
  end

  before do
    Stub.service(:course, build(:'course:root'))
    enrollment_stub
  end

  describe '(validations)' do
    it { is_expected.to be_valid }
    it { is_expected.to accept_values_for(:type, 'ConfirmationOfParticipation', 'RecordOfAchievement', 'Certificate') }
    it { is_expected.not_to accept_values_for(:type, nil, 'InvalidType') }

    context 'without enrollment' do
      let(:enrollments) { Stub.json([]) }

      it { is_expected.not_to be_valid }
    end

    context 'when records are not released' do
      let(:records_released) { false }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#by_code' do
    context 'returns most valuable certificate with same code' do
      subject(:record_by_code) { described_class.by_code(verification).first }

      let(:verification) { 'the-verification-code' }
      let!(:cop) { create(:cop, user:, course:, verification:) }

      it 'returns the CoP' do
        expect(record_by_code).to eq cop
      end

      context 'with RoA for same user and course' do
        let!(:roa) { create(:roa, user:, course:, verification:) }

        it 'returns the RoA' do
          expect(record_by_code).to eq roa
        end
      end
    end
  end

  describe '#verify' do
    subject(:verification_result) { Certificate::Record.verify(verification) }

    let(:verification) { 'the-verification-code' }

    context 'with a valid verification code' do
      before do
        create(:roa, user:, course:, verification:)
      end

      it 'verifies the record successfully' do
        expect(verification_result).to be_a(Certificate::RecordPresenter)
      end
    end

    context 'with an invalid verification code' do
      it 'raises an error' do
        expect { verification_result }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a deleted user' do
      let(:user) { create(:user, :archived) }

      before do
        create(:roa, user:, course:, verification:)
      end

      it 'returns an archived user' do
        expect(verification_result).to be_user_deleted
      end
    end
  end

  # We explicitly test the logic of this private method because we cannot
  # influence its input verification code, which is generated randomly in
  # the public API (Record#add_verification_hash)
  describe '#filter_forbidden_words' do
    let(:verification_code) { 'stop1-klaus-stop2' }
    let(:clean_verification_code) { record.send(:filter_forbidden_words, verification_code, 'the_token') }

    before do
      xi_config <<~YML
        certificate:
          forbidden_verification_words: ['stop1', 'stop2']
      YML
    end

    it 'removes forbidden words' do
      clean_verification_code.split('-').each do |word|
        expect(Xikolo.config.certificate['forbidden_verification_words']).not_to include(word)
      end
    end

    context 'without forbidden word' do
      let(:verification_code) { 'xyxzx-klaus-zafec' }

      it 'does not change the verification code' do
        expect(clean_verification_code).to eq verification_code
      end
    end
  end
end
