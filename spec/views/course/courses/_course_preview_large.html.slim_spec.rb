# frozen_string_literal: true

require 'spec_helper'

describe 'course/courses/_course_preview_large.html.slim', type: :view do
  subject { render_view; rendered }

  let(:enrollment_id) { '00000001-636e-4444-9999-000000000045' }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'features' => features,
      'user' => {'anonymous' => anonymous}
    )
  end
  let(:features) { {} }
  let(:anonymous) { false }
  let(:course) { create(:course, id: '00000001-636e-4444-9999-000000000044', **course_attrs.except(:public)) }
  let(:course_resource) { Xikolo::Course::Course.new(id: course.id, **course_attrs) }
  let(:course_attrs) { {course_code: 'test', lang: 'en'} }
  let(:course_presenter) { CourseLargePreviewPresenter.build(course_resource, user, enrollments) }
  let(:enrollments) { nil }
  let(:social_sharing_presenter) { nil }
  let(:render_view) { render 'course/courses/course_preview_large', course: course_presenter, social_sharing: social_sharing_presenter, current_user: user }

  context 'show' do
    context 'as anonymous user' do
      let(:anonymous) { true }

      it { is_expected.to include 'Enroll me for this course' }
      it { is_expected.not_to include 'Un-enroll' }
      it { is_expected.not_to include 'Clone course' }
      it { is_expected.not_to include 'Book a Certificate' }
    end

    context 'as enrolled user' do
      let(:enrollments) { [Course::Enrollment.new(course_id: course.id, id: enrollment_id)] }

      it { is_expected.to include 'Enter course' }
      it { is_expected.to include 'Un-enroll' }
      it { is_expected.not_to include 'Clone course' }
      it { is_expected.not_to include 'Book a Certificate' }
      it { is_expected.not_to include 'You have booked a Certificate.' }
      it { is_expected.not_to include 'Booking a Certificate is no longer possible.' }

      context 'for an invite-only course with external registration' do
        let(:course_attrs) { super().merge invite_only: true, external_registration_url: {en: 'http://foo.bar'} }

        it { is_expected.not_to include 'Un-enroll' }
        it { is_expected.to include 'To un-enroll from the course, contact the course provider.' }
      end

      context 'with proctoring enabled and proctored course' do
        let(:course_attrs) { super().merge(proctored: true) }
        let(:features) { {'proctoring' => true} }

        before do
          allow(Proctoring).to receive(:enabled?).and_return true
        end

        context 'without upgraded enrollment' do
          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(Proctoring::CourseContext).to receive(:upgrade_possible?).and_return(upgrade_possible)
            # rubocop:enable RSpec/AnyInstance
          end

          context 'upgrade possible' do
            let(:upgrade_possible) { true }

            it { is_expected.to include 'Book a Certificate' }
            it { is_expected.not_to include 'You have booked a Certificate.' }
            it { is_expected.not_to include 'Booking a Certificate is no longer possible.' }
          end

          context 'upgrade not possible' do
            let(:upgrade_possible) { false }

            it { is_expected.to include 'Book a Certificate' }
            it { is_expected.not_to include 'You have booked a Certificate.' }
            it { is_expected.to include 'Booking a Certificate is no longer possible.' }
          end
        end

        context 'with upgraded enrollment' do
          let(:enrollments) { [Xikolo::Course::Enrollment.new(course_id: course.id, id: enrollment_id, proctored: true)] }

          context 'registered with SMOWL' do
            before do
              allow(course_presenter).to receive(:show_smowl_registration_notice?).and_return(true)
            end

            it { is_expected.not_to include 'Book a Certificate' }
            it { is_expected.to include 'You have booked a Certificate.' }
            it { is_expected.to include 'Please calibrate your image with our partner.' }
          end

          context 'not registered with SMOWL' do
            before do
              allow(course_presenter).to receive(:show_smowl_registration_notice?).and_return(false)
            end

            it { is_expected.not_to include 'Book a Certificate' }
            it { is_expected.to include 'You have booked a Certificate.' }
            it { is_expected.not_to include 'Please calibrate your image with our partner.' }
          end
        end
      end
    end

    context 'for external course' do
      let(:course_attrs) { super().merge(external_course_url: 'https://example.com/external') }

      it { is_expected.not_to include 'Enroll me for this course' }
      it { is_expected.not_to include 'Enter course' }
      it { is_expected.not_to include 'Un-enroll' }
      it { is_expected.to include 'Go to external course' }
    end

    context 'as not enrolled user' do
      let(:enrollments) { nil }
      let(:enrolled) { false }

      it { is_expected.to include 'Enroll me for this course' }
      it { is_expected.not_to include 'Clone course' }
      it { is_expected.not_to include 'Book a Certificate' }
    end

    context 'for an invite-only course with external registration' do
      let(:course_attrs) { super().merge(invite_only: true, external_registration_url: {en: 'http://foo.bar'}) }

      it { is_expected.not_to include 'Enroll me for this course' }
      it { is_expected.to include 'Register now' }
    end

    context '(social media buttons)' do
      let(:social_sharing_presenter) { SocialSharingPresenter.new(context: :course) }
      let(:course_attrs) { super().merge(public: true) }

      describe 'for regular course' do
        it { is_expected.to render_template 'shared/_social_sharing' }
      end

      describe 'for hidden course' do
        let(:course_attrs) { super().merge(public: false) }

        it { is_expected.not_to render_template 'shared/_social_sharing' }
      end
    end
  end
end
