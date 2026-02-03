# frozen_string_literal: true

require 'spec_helper'

describe Course::DocumentsPresenter do
  let(:presenter) do
    described_class.new(user_id:, course:, current_user: user).tap do
      Acfs.run
    end
  end
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user' => {'anonymous' => false},
      'features' => features
    )
  end
  let(:features) { {} }
  let(:course) { create(:course) }
  let(:user_id) { generate(:user_id) }
  let(:cop) { false }
  let(:roa) { false }
  let(:cert) { false }
  let(:certificates_data) { {confirmation_of_participation: cop, record_of_achievement: roa, certificate: cert} }
  let(:enrollment_proctored) { false }
  let(:enrollment_params) { {proctored: enrollment_proctored, certificates: certificates_data} }

  before do
    Stub.request(
      :course, :get, "/courses/#{course.id}"
    ).to_return Stub.json({id: course.id})

    Stub.request(
      :course, :get, "/enrollments?course_id=#{course.id}&learning_evaluation=true&user_id=#{user_id}"
    ).to_return Stub.json([
      enrollment_params.merge(course_id: course.id),
    ])
  end

  shared_context 'proctoring enabled and set up' do
    let(:features) { {'proctoring' => true} }

    before { allow(Proctoring).to receive(:enabled?).and_return true }
  end

  shared_context 'user received certificate' do
    let(:cert) { true }
    let(:enrollment_proctored) { true }
  end

  shared_examples_for 'correct proctoring and user cert validation' do |result_proctoring_passed:, result_proctoring_failed:|
    context 'proctoring feature not enabled or not set up correctly' do
      it { is_expected.to be false }
    end

    context 'proctoring feature enabled and set up correctly' do
      include_context 'proctoring enabled and set up'

      context 'certificate not received by user' do
        it { is_expected.to be false }
      end

      context 'certificate received by user' do
        include_context 'user received certificate'

        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(DocumentsPresenter).to receive(:user_passed_proctoring?).and_return proctoring_passed
          # rubocop:enable RSpec/AnyInstance
        end

        context 'the user did not pass proctoring for course' do
          let(:proctoring_passed) { false }

          it { is_expected.to eq result_proctoring_failed }
        end

        context 'the user passed proctoring for course' do
          let(:proctoring_passed) { true }

          it { is_expected.to eq result_proctoring_passed }
        end
      end
    end
  end

  describe '#cop?' do
    subject { presenter.cop? }

    context 'not received cop' do
      it { is_expected.to be_falsy }
    end

    context 'received cop' do
      before do
        create(:certificate_template, :cop, course:)
      end

      let(:cop) { true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#roa?' do
    subject { presenter.roa? }

    context 'not received roa' do
      it { is_expected.to be_falsy }
    end

    context 'received roa' do
      before do
        create(:certificate_template, :roa, course:)
      end

      let(:roa) { true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#cert?' do
    subject { presenter.cert? }

    context 'not received cert' do
      it { is_expected.to be_falsy }
    end

    context 'received cert' do
      before do
        create(:certificate_template, :certificate, course:)
      end

      include_context 'user received certificate'

      it { is_expected.to be_truthy }
    end
  end

  describe '#cert_enabled?' do
    subject { presenter.cert_enabled? }

    context 'proctoring feature not enabled (feature flipper)' do
      it { is_expected.to be_falsy }
    end

    context 'proctoring feature enabled (feature flipper)' do
      let(:features) { {'proctoring' => true} }
      let(:proctoring_enabled) { false }

      before { allow(Proctoring).to receive(:enabled?).and_return proctoring_enabled }

      context 'proctoring not configured' do
        it { is_expected.to be_falsy }
      end

      context 'proctoring configured' do
        let(:proctoring_enabled) { true }

        context 'the user\'s enrollment is not proctored' do
          let(:enrollment_proctored) { false }

          it { is_expected.to be false }
        end

        context 'the user\'s enrollment is proctored' do
          let(:enrollment_proctored) { true }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#certificate_download?' do
    subject { presenter.certificate_download? }

    before do
      create(:certificate_template, :certificate, course:)
    end

    it_behaves_like 'correct proctoring and user cert validation',
      result_proctoring_passed: true,
      result_proctoring_failed: false
  end
end
