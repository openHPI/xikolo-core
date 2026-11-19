# frozen_string_literal: true

require 'spec_helper'

describe CourseInfoPresenter do
  subject(:presenter) { described_class.build course, user }

  let(:course_params) { {} }
  let(:course) { create(:'course_service/course', course_params) }

  let(:user) do
    CurrentUser::User.new(
      session: create(:'account_service/session'),
      context_id: 'root'
    )
  end

  describe '#date_label' do
    subject(:label) { presenter.date_label }

    let(:published) { false }

    context 'with no display_start_date nor end_date' do
      let(:course) { create(:'course_service/course', published: published) }

      context 'with being archived' do
        it { expect(label).to eq 'Coming soon' }
      end
    end

    context 'with end_date in the past' do
      let(:end_date) { 7.days.ago }
      let(:course) { create(:'course_service/course', end_date:) }
      let(:published) { true }

      context 'with active status' do
        it 'shows the end date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(end_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:published) { false }

        it 'shows the end date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(end_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date in the past and no end_date' do
      let(:display_start_date) { 7.days.ago }
      let(:course) do
        create(:'course_service/course', display_start_date:, end_date: nil, published:)
      end

      before do
        course
      end

      context 'with active status' do
        let(:published) { true }

        it 'shows the past start date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:published) { false }

        it 'shows the past start date in the label' do
          expect(label).to eq "Self-paced since #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date in the future and no end_date' do
      let(:display_start_date) { 7.days.from_now }
      let(:course) { create(:'course_service/course', display_start_date:, end_date: nil) }

      context 'with active status' do
        let(:published) { true }

        it 'shows the upcoming start date in the label' do
          expect(label).to eq "Beginning #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end

      context 'with being archived' do
        let(:published) { false }

        it 'shows the upcoming start date in the label' do
          expect(label).to eq "Beginning #{I18n.l(display_start_date, format: :short_datetime)}"
        end
      end
    end

    context 'with display_start_date and end_date (not in past)' do
      let(:display_start_date) { 7.days.ago }
      let(:end_date) { 7.days.from_now }
      let(:course) { create(:'course_service/course', display_start_date:, end_date:, published:) }

      context 'with active status' do
        let(:published) { true }

        it 'shows the time range in the label' do
          expect(label).to include I18n.l(display_start_date, format: :short_datetime)
          expect(label).to include I18n.l(end_date, format: :short_datetime)
        end
      end

      context 'with being archived' do
        let(:published) { false }

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

  describe '#external?' do
    it { is_expected.not_to be_external }

    context 'with external course URL' do
      let(:course_params) { {external_course_url: 'http://external'} }

      it { is_expected.to be_external }
    end
  end

  describe '#show_certificate_requirements?' do
    context 'RoA or COP enabled' do
      let(:course_params) { super().merge roa_enabled: true, cop_enabled: false }

      it { is_expected.to be_show_certificate_requirements }
    end

    context 'RoA nor COP enabled' do
      let(:course_params) { super().merge roa_enabled: false, cop_enabled: false }

      it { is_expected.not_to be_show_certificate_requirements }
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

    context 'without a course visual' do
      let(:course) { create(:course) }

      before { course }

      it { is_expected.to match %r{/assets/defaults/course-[a-z0-9]+\.png} }
    end

    context 'with a course visual' do
      let(:course) { create(:course, :with_visual) }

      before { course }

      it { is_expected.to match %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}x }
    end
  end

  describe '#category_titles' do
    subject(:category_titles) { presenter.category_titles }

    let(:topic) { create(:cluster, :visible, id: 'topic') }
    let(:level) { create(:cluster, :visible, id: 'level') }
    let(:course) { create(:'course_service/course') }

    before do
      course.classifiers << create(:classifier, cluster: topic, title: 'general', translations: {en: 'General', de: 'Allgemein'})
      course.classifiers << create(:classifier, cluster: topic, title: 'ai', translations: {en: 'AI', de: 'KI'})
      course.classifiers << create(:classifier, cluster: level, title: 'beginner', translations: {en: 'Beginner', de: 'Anfänger'})
    end

    it 'lists the classifiers except the level, sorted' do
      expect(category_titles).to eq %w[AI General]
    end

    it 'displays the best translation' do
      I18n.with_locale(:de) do
        expect(category_titles).to eq %w[Allgemein KI]
      end
    end

    context 'with an invisible cluster' do
      let(:invisible) { create(:cluster, :invisible, id: 'invisible') }

      before do
        create(:classifier, cluster: invisible, title: 'internal', translations: {en: 'Internal', de: 'Intern'})
      end

      it 'only shows the classifiers for the visible clusters' do
        expect(category_titles).to eq %w[AI General]
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
        expect(category_titles).to be_empty
      end
    end
  end
end
