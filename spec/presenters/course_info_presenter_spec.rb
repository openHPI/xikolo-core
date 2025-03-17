# frozen_string_literal: true

require 'spec_helper'

describe CourseInfoPresenter do
  subject(:presenter) { described_class.build course, user }

  let(:course_params) { {} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:permissions) { [] }
  let(:features) { {} }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'id' => 1,
      'permissions' => permissions,
      'features' => features,
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end

  describe '#date_label' do
    subject(:label) { presenter.date_label }

    context 'with no display_start_date nor end_date' do
      let(:course) { Xikolo::Course::Course.new status: }

      context 'with active status' do
        let(:status) { 'active' }

        it { expect(label).to eq 'Coming soon' }
      end

      context 'with being archived' do
        let(:status) { 'archive' }

        it { expect(label).to eq 'Coming soon' }
      end
    end

    context 'with end_date in the past' do
      let(:end_date) { 7.days.ago }
      let(:course) { Xikolo::Course::Course.new end_date:, status: }

      context 'with active status' do
        let(:status) { 'active' }

        it 'shows the end date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(end_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:status) { 'archive' }

        it 'shows the end date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(end_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date in the past and no end_date' do
      let(:display_start_date) { 7.days.ago }
      let(:course) do
        Xikolo::Course::Course.new display_start_date:, end_date: nil, status:
      end

      context 'with active status' do
        let(:status) { 'active' }

        it 'shows the past start date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:status) { 'archive' }

        it 'shows the past start date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date in the future and no end_date' do
      let(:display_start_date) { 7.days.from_now }
      let(:course) do
        Xikolo::Course::Course.new display_start_date:, end_date: nil, status:
      end

      context 'with active status' do
        let(:status) { 'active' }

        it 'shows the upcoming start date in the label' do
          expect(label).to eq "Beginning #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:status) { 'archive' }

        it 'shows the upcoming start date in the label' do
          expect(label).to eq "Beginning #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date and end_date (not in past)' do
      let(:display_start_date) { 7.days.ago }
      let(:end_date) { 7.days.from_now }
      let(:course) do
        Xikolo::Course::Course.new display_start_date:, end_date:, status:
      end

      context 'with active status' do
        let(:status) { 'active' }

        it 'shows the time range in the label' do
          expect(label).to include I18n.l(display_start_date, format: :short_datetime)
          expect(label).to include I18n.l(end_date, format: :short_datetime)
        end
      end

      context 'with being archived' do
        let(:status) { 'archive' }

        it 'shows the time range in the label' do
          expect(label).to include I18n.l(display_start_date, format: :short_datetime)
          expect(label).to include I18n.l(end_date, format: :short_datetime)
        end
      end
    end

    context 'with date label disabled' do
      before do
        xi_config <<~YML
          course_details:
            show_date_label: false
        YML
      end

      it 'has no date label' do
        expect(label).to be_nil
      end
    end
  end

  describe '#enrollment_policy?' do
    subject { presenter.enrollment_policy? }

    context 'when the course policy_url is blank' do
      it { is_expected.to be_falsey }
    end

    context 'when the course policy_url is present' do
      let(:course_params) do
        super().merge(
          policy_url: {
            'en' => 'https://xikolo.de/test2018/policies.en.html',
            'de' => 'https://xikolo.de/test2018/policies.de.html',
          }
        )
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#enrollment_policy_url' do
    subject(:policy_url) { presenter.enrollment_policy_url }

    context 'when the course does not have a policy url' do
      it { is_expected.to be_nil }
    end

    context 'when the course has a policy URL' do
      let(:course_params) do
        super().merge(
          policy_url: {
            'en' => 'https://xikolo.de/test/policies.en.html',
            'de' => 'https://xikolo.de/test/policies.de.html',
          }
        )
      end

      it 'uses the correct policy URL for English' do
        I18n.with_locale(:en) do
          expect(policy_url).to eq('https://xikolo.de/test/policies.en.html')
        end
      end

      it 'uses the correct policy URL for German' do
        I18n.with_locale(:de) do
          expect(policy_url).to eq('https://xikolo.de/test/policies.de.html')
        end
      end
    end
  end

  describe '#external_registration_url?' do
    subject { presenter.external_registration_url? }

    context 'for a regular course' do
      it { is_expected.to be_falsey }
    end

    context 'for a course with external registration' do
      let(:course_params) do
        super().merge(
          external_registration_url: {
            'en' => 'https://external.registration.en.html',
            'de' => 'https://external.registration.de.html',
          }
        )
      end

      it { is_expected.to be_falsey }
    end

    context 'for an invite-only course' do
      let(:course_params) { super().merge(invite_only: true) }

      it { is_expected.to be_falsey }
    end

    context 'for an invite-only course with external registration' do
      let(:course_params) do
        super().merge(
          external_registration_url: {
            'en' => 'https://external.registration.en.html',
            'de' => 'https://external.registration.de.html',
          },
          invite_only: true
        )
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#external_registration_url' do
    subject(:registration_url) { presenter.external_registration_url }

    context 'when the external registration URL is not set' do
      it { is_expected.to be_nil }
    end

    context 'when an external registration URL is set' do
      let(:course_params) do
        super().merge(
          external_registration_url: {
            'en' => 'https://external.registration.en.html',
            'de' => 'https://external.registration.de.html',
          }
        )
      end

      it 'uses the correct registration URL for English' do
        I18n.with_locale(:en) do
          expect(registration_url).to eq('https://external.registration.en.html')
        end
      end

      it 'uses the correct registration URL for German' do
        I18n.with_locale(:de) do
          expect(registration_url).to eq('https://external.registration.de.html')
        end
      end

      context 'when using an external booking system' do
        let(:features) { {'integration.external_booking' => true} }

        before do
          allow(ExternalRegistration::JwtTokenGenerator).to receive(:call).once.and_return('mytoken')
        end

        it 'provides the user\'s JWT token for the English registration URL' do
          I18n.with_locale(:en) do
            expect(registration_url).to eq('https://external.registration.en.html?jwt=mytoken')
          end
        end

        it 'provides the user\'s JWT token for the German registration URL' do
          I18n.with_locale(:de) do
            expect(registration_url).to eq('https://external.registration.de.html?jwt=mytoken')
          end
        end
      end
    end
  end

  describe '#external?' do
    it { is_expected.not_to be_external }

    context 'with external course URL' do
      let(:course_params) { {external_course_url: 'http://external'} }

      it { is_expected.to be_external }
    end
  end

  describe '#show_certificate_requirements?' do
    context 'with feature disabled' do
      it { is_expected.not_to be_show_certificate_requirements }
    end

    context 'with feature enabled' do
      let(:features) { {'certificate_requirements' => true} }

      context 'RoA or COP enabled' do
        let(:course_params) { super().merge roa_enabled: true, cop_enabled: false }

        it { is_expected.to be_show_certificate_requirements }
      end

      context 'ToR available' do
        let(:course_id) { SecureRandom.uuid }
        let(:course_params) { super().merge id: course_id, roa_enabled: false, cop_enabled: false }

        before do
          xi_config <<~YML
            certificate:
              transcript_of_records:
                table_x: 200
                table_y: 500
                course_col_width: 300
                score_col_width: 70
                font_size: 10
          YML

          create(:course, id: course_id)
          create(:certificate_template, :tor, course_id:)
        end

        it { is_expected.to be_show_certificate_requirements }
      end

      context 'RoA nor COP enabled' do
        let(:course_params) { super().merge roa_enabled: false, cop_enabled: false }

        it { is_expected.not_to be_show_certificate_requirements }
      end
    end
  end

  describe '#rating_widget_enabled?' do
    let(:course_attributes) do
      {
        public: true,
        display_start_date: 1.day.ago,
        invite_only: false,
        hidden: false,
      }
    end
    let(:course) { Xikolo::Course::Course.new course_attributes }

    it { is_expected.not_to be_rating_widget_enabled }

    context 'with enabled feature' do
      let(:features) { {'course_rating' => true} }

      it { is_expected.to be_rating_widget_enabled }

      context 'with non-public course' do
        let(:course_attributes) { super().merge(public: false) }

        it { is_expected.to be_rating_widget_enabled }
      end

      context 'with future course' do
        let(:course_attributes) { super().merge(display_start_date: 1.day.from_now) }

        it { is_expected.not_to be_rating_widget_enabled }
      end

      context 'with an invite-only course' do
        let(:course_attributes) { super().merge(invite_only: true) }

        it { is_expected.not_to be_rating_widget_enabled }
      end

      context 'without course start date' do
        let(:course_attributes) { super().merge(display_start_date: nil, start_date: nil) }

        it { is_expected.to be_rating_widget_enabled }
      end
    end
  end

  describe '#pinboard_enabled' do
    it 'is enabled by default' do
      expect(presenter.pinboard_enabled).to be_truthy
    end

    context 'with disabled pinboard' do
      let(:course_params) { {pinboard_enabled: false} }

      it 'is disabled' do
        expect(presenter.pinboard_enabled).to be_falsey
      end
    end
  end

  describe '#visual_url' do
    subject { presenter.visual_url }

    let(:course) { Xikolo::Course::Course.new id: generate(:course_id) }

    context 'without a course visual' do
      before { create(:course, id: course.id) }

      it { is_expected.to match %r{/assets/defaults/course-[a-z0-9]+\.png} }
    end

    context 'with a course visual' do
      before { create(:course, :with_visual, id: course.id) }

      it { is_expected.to match %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}x }
    end
  end

  describe '(classifiers)' do
    subject(:classifier_string) { presenter.public_classifiers_string }

    let(:topic) { create(:cluster, :visible, id: 'topic') }
    let(:level) { create(:cluster, :visible, id: 'level') }
    let(:course_params) do
      super().merge(
        classifiers: {
          'level' => 'beginner',
          'topic' => 'general',
        }
      )
    end

    before do
      create(:classifier, cluster: topic, title: 'general', translations: {en: 'General', de: 'Allgemein'})
      create(:classifier, cluster: level, title: 'beginner', translations: {en: 'Beginner', de: 'Anfänger'})
    end

    it 'lists all classifiers' do
      expect(classifier_string).to eq 'Beginner, General'
    end

    it 'displays the best translation' do
      I18n.with_locale(:de) do
        expect(classifier_string).to eq 'Allgemein, Anfänger'
      end
    end

    context 'with an invisible cluster' do
      let(:invisible) { create(:cluster, :invisible, id: 'invisible') }

      before do
        create(:classifier, cluster: invisible, title: 'internal', translations: {en: 'Internal', de: 'Intern'})
      end

      it 'only shows the classifiers for the visible clusters' do
        expect(classifier_string).to eq 'Beginner, General'
      end
    end

    context 'with classifiers disabled for course details page' do
      before do
        xi_config <<~YML
          course_details:
            list_classifiers: false
        YML
      end

      it 'has no public classifiers' do
        expect(classifier_string).to be_nil
      end
    end
  end
end
