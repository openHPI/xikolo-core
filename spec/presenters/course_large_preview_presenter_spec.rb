# frozen_string_literal: true

require 'spec_helper'

describe CourseLargePreviewPresenter, type: :presenter do
  subject(:presenter) { described_class.build(course, user, [enrollment]) }

  let(:course) { Xikolo::Course::Course.new course_params.merge id: course_id }
  let(:course_id) { generate(:course_id) }
  let(:course_params) { {proctored: course_proctored} }
  let(:course_proctored) { false }
  let(:enrollment) do
    Xikolo::Course::Enrollment.new(
      course_id: course.id,
      completed:,
      proctored: enrollment_proctored
    )
  end
  let(:completed) { false }
  let(:enrollment_proctored) { false }
  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user_id' => generate(:user_id),
      'permissions' => permissions,
      'features' => features,
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end
  let(:permissions) { [] }
  let(:features) { {} }
  let(:video) { create(:video, pip_stream: stream) }
  let(:stream) { create(:stream) }

  before do
    course = create(:course, :active, :with_teaser_video,
      id: course_id,
      proctored: course_proctored,
      video:)
    create(:enrollment,
      id: enrollment.id,
      course:,
      user_id: user.id,
      proctored: enrollment_proctored)
  end

  describe '#video' do
    subject(:video_player) { presenter.video.player }

    context 'with a video hosted on Vimeo' do
      let(:stream) { create(:stream, :vimeo) }

      it 'uses the generic video player' do
        expect(video_player).to be_a Video::VideoPlayer
      end
    end

    context 'with a video hosted on Kaltura' do
      let(:stream) { create(:stream, :kaltura) }

      it 'uses the generic video player' do
        expect(video_player).to be_a Video::VideoPlayer
      end
    end
  end

  describe '#access_allowed?' do
    let(:was_available) { true }

    before { allow(course).to receive(:was_available?).and_return(was_available) }

    it { is_expected.to be_access_allowed }

    context 'with never available course' do
      let(:was_available) { false }

      it { is_expected.not_to be_access_allowed }

      context 'with course.content.access permission' do
        let(:permissions) { ['course.content.access'] }

        it { is_expected.to be_access_allowed }
      end

      context 'when not logged in' do
        let(:user) { anonymous }

        it { is_expected.not_to be_access_allowed }
      end
    end

    context 'with external_course_url' do
      before { course.external_course_url = 'http://test' }

      it { is_expected.not_to be_access_allowed }

      context 'with course.content.access' do
        let(:permissions) { ['course.content.access'] }

        it { is_expected.to be_access_allowed }
      end
    end

    context 'with empty external_course_url' do
      before { course.external_course_url = '' }

      it { is_expected.to be_access_allowed }

      context 'with course.content.access' do
        let(:permissions) { ['course.content.access'] }

        it { is_expected.to be_access_allowed }
      end
    end
  end

  describe '(proctoring)' do
    let(:proctoring_context) { presenter.proctoring_context }
    let(:course_proctored) { true }
    let(:enrollment_proctored) { true }
    let(:registration_status) { :complete }

    before do
      allow(Proctoring).to receive(:enabled?).and_return true

      allow(Proctoring::SmowlAdapter).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap do |adapter|
          allow(adapter).to receive(:registration_status).and_return(
            Proctoring::RegistrationStatus.new(registration_status)
          )
        end
      end
    end

    describe '#show_proctoring_impossible_message?' do
      subject { super().show_proctoring_impossible_message? }

      context 'with disabled proctoring feature' do
        it { is_expected.to be false }
      end

      context 'with enabled proctoring feature' do
        let(:features) { {'proctoring' => true} }

        context 'with proctored enrollment' do
          it { is_expected.to be false }
        end

        context 'with not proctored enrollment' do
          let(:enrollment_proctored) { false }

          context 'upgrade possible' do
            before do
              allow(proctoring_context).to receive(:upgrade_possible?).and_return true
            end

            it { is_expected.to be false }
          end

          context 'upgrade not possible' do
            before do
              allow(proctoring_context).to receive(:upgrade_possible?).and_return false
            end

            it { is_expected.to be true }
          end
        end
      end
    end

    describe '#proctoring_enabled?' do
      subject { super().proctoring_enabled? }

      context 'with disabled proctoring feature' do
        it { is_expected.to be false }
      end

      context 'with enabled proctoring feature' do
        let(:features) { {'proctoring' => true} }

        context 'with not proctored enrollment' do
          let(:enrollment_proctored) { false }

          it { is_expected.to be false }
        end

        context 'with proctored enrollment' do
          it { is_expected.to be true }
        end
      end
    end

    describe '#upgrade_proctoring?' do
      subject { super().upgrade_proctoring? }

      context 'with disabled proctoring feature' do
        it { is_expected.to be false }
      end

      context 'with enabled proctoring feature' do
        let(:features) { {'proctoring' => true} }

        context 'with proctored enrollment' do
          it { is_expected.to be false }
        end

        context 'with not proctored enrollment' do
          let(:enrollment_proctored) { false }

          it { is_expected.to be true }
        end
      end
    end

    describe '#show_smowl_registration_notice?' do
      subject { super().show_smowl_registration_notice? }

      context 'with disabled proctoring feature' do
        it { is_expected.to be false }
      end

      context 'with enabled proctoring feature' do
        let(:features) { {'proctoring' => true} }

        context 'with registration at smowl' do
          it { is_expected.to be false }
        end

        context 'without registration at smowl' do
          let(:registration_status) { :required }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#show_social_media_buttons?' do
    context 'regular course' do
      let(:course_params) { super().merge public: true }

      it { is_expected.to be_show_social_media_buttons }

      context 'that has not started yet' do
        let(:course_params) { super().merge(start_date: 1.week.from_now) }

        it { is_expected.to be_show_social_media_buttons }
      end
    end

    context 'non-public course' do
      let(:course_params) { super().merge public: false }

      it { is_expected.not_to be_show_social_media_buttons }
    end
  end

  describe '#unenrollment_enabled?' do
    subject(:unenrollment_enabled) { presenter.unenrollment_enabled? }

    it 'is enabled for a regular course' do
      expect(unenrollment_enabled).to be_truthy
    end

    context 'for an invite-only course' do
      let(:course_params) { super().merge invite_only: true }

      it 'is enabled' do
        expect(unenrollment_enabled).to be_truthy
      end

      context 'with external registration' do
        let(:course_params) { super().merge external_registration_url: {en: 'the-link'} }

        it 'is disabled' do
          expect(unenrollment_enabled).to be_falsey
        end
      end
    end
  end
end
