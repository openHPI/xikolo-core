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
end
