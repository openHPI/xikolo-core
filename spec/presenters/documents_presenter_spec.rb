# frozen_string_literal: true

require 'spec_helper'

describe DocumentsPresenter, type: :presenter do
  subject { presenter }

  let(:course) { create(:course) }
  let(:cop) { false }
  let(:roa) { false }
  let(:cert) { false }
  let(:certificates_data) { {confirmation_of_participation: cop, record_of_achievement: roa, certificate: cert} }
  let(:enrollment_proctored) { false }
  let(:enrollment_params) { {completed: true, proctored: enrollment_proctored, certificates: certificates_data} }
  let(:enrollment) { Xikolo::Course::Enrollment.new enrollment_params.merge course_id: course.id }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user' => {'anonymous' => false},
      'features' => features
    )
  end
  let(:features) { {} }
  let(:presenter) { described_class.new(course:, enrollment:, user:) }

  describe 'cop?' do
    context 'not received cop' do
      it 'cop should not be available' do
        expect(presenter.cop?).to be false
      end
    end

    context 'received cop' do
      let(:cop) { true }

      context 'with available template' do
        before do
          create(:certificate_template, :cop, course:)
        end

        it 'cop should be available' do
          expect(presenter.cop?).to be true
        end
      end

      context 'without available template' do
        it 'cop should not be available' do
          expect(presenter.cop?).to be false
        end
      end
    end
  end

  describe 'roa?' do
    context 'not received roa' do
      it 'roa should not be available' do
        expect(presenter.roa?).to be false
      end
    end

    context 'received roa' do
      let(:roa) { true }

      context 'with available template' do
        before do
          create(:certificate_template, :roa, course:)
        end

        it 'roa should be available' do
          expect(presenter.roa?).to be true
        end
      end

      context 'without available template' do
        it 'roa should not be available' do
          expect(presenter.roa?).to be false
        end
      end
    end
  end
end
