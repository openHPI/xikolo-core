# frozen_string_literal: true

require 'spec_helper'

describe Home::CourseCard, type: :component do
  subject(:component) do
    described_class.new(queried_course, user:, enrollment:, type:)
  end

  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course, :active) }
  let(:queried_course) { Catalog::Course.find(course.id) }

  let(:user) { nil }
  let(:enrollment) { nil }
  let(:type) { nil }
  let(:features) { {} }

  describe 'extended info section' do
    let(:course) { create(:course, :active, :with_teachers) }

    context 'in a expandable card' do
      let(:type) { 'expandable' }

      it 'is shown' do
        render_inline(component)

        expect(page).to have_content 'Abstract text'
        expect(page).to have_content 'Doctor Who'
      end
    end

    context 'in a compact card' do
      let(:type) { 'compact' }

      it 'is not shown' do
        render_inline(component)

        expect(page).to have_no_content 'Abstract text'
        expect(page).to have_no_content 'Doctor Who'
      end
    end
  end

  describe 'buttons' do
    context 'in a non-collapsed card' do
      let(:type) { 'expandable' }

      context 'without a user' do
        it 'only shows the details button' do
          render_inline(component)

          expect(page).to have_link 'Details'
          expect(page).to have_no_link 'Resume'
          expect(page).to have_no_link 'Enroll'
          expect(page).to have_no_link 'Reactivate'
        end
      end

      context 'with a user' do
        let(:user) do
          Xikolo::Common::Auth::CurrentUser.from_session(
            'features' => features,
            'user_id' => user_id,
            'user' => {'anonymous' => false}
          )
        end

        context 'with an external url' do
          let(:course) { create(:course, :active, :external) }

          it 'displays a goto external link' do
            render_inline(component)

            expect(page).to have_link 'Visit', href: course.external_course_url
          end

          it 'displays details link' do
            render_inline(component)

            expect(page).to have_link 'Details'
          end

          it 'does not display other links' do
            render_inline(component)

            expect(page).to have_no_link 'Resume'
            expect(page).to have_no_link 'Enroll'
            expect(page).to have_no_link 'Reactivate'
          end
        end

        context 'when enrolled in the course' do
          let(:enrollment) { Course::Enrollment.new(course:, user_id:) }

          it 'displays a resume link' do
            render_inline(component)

            expect(page).to have_link 'Resume'
          end

          it 'displays details link' do
            render_inline(component)

            expect(page).to have_link 'Details'
          end

          it 'does not display other links' do
            render_inline(component)

            expect(page).to have_no_link 'Visit'
            expect(page).to have_no_link 'Enroll'
            expect(page).to have_no_link 'Reactivate'
          end
        end

        context 'with an enroll-able course' do
          context 'with a policy url' do
            let(:course) { create(:course, :active, policy_url:) }
            let(:policy_url) { {en: 'https://test.mock/en/policy'} }

            it 'displays a button to enroll in the course, which opens a dialog requiring to accept the policy' do
              render_inline(component)

              expect(page).to have_button 'Enroll'
              expect(page).to have_link 'Show policy', href: 'https://test.mock/en/policy'
            end

            it 'displays the course details link only' do
              render_inline(component)

              expect(page).to have_link 'Details'
              expect(page).to have_no_link 'Resume'
              expect(page).to have_no_link 'Visit'
              expect(page).to have_no_link 'Reactivate'
            end
          end

          context 'without a policy url' do
            it 'displays a link to enroll in the course, without requiring to accept the policy' do
              render_inline(component)

              expect(page).to have_link 'Enroll'
            end

            it 'displays the course details link only' do
              render_inline(component)

              expect(page).to have_link 'Details'
              expect(page).to have_no_link 'Resume'
              expect(page).to have_no_link 'Visit'
              expect(page).to have_no_link 'Reactivate'
            end
          end
        end

        context 'with an non enroll-able course' do
          let(:course) { create(:course, :active, invite_only: true) }

          it 'displays the course details link only' do
            render_inline(component)

            expect(page).to have_link 'Details'
            expect(page).to have_no_link 'Enroll'
            expect(page).to have_no_link 'Resume'
            expect(page).to have_no_link 'Visit'
            expect(page).to have_no_link 'Reactivate'
          end
        end

        describe 'with course reactivation available' do
          let(:features) { {'course_reactivation' => true} }
          let(:course) { create(:course, :archived, :offers_reactivation, deleted: false) }

          before do
            Xikolo.config.voucher['enabled'] = true
          end

          describe 'for not enrolled users' do
            it 'displays a link to reactivate the course and an enroll link' do
              render_inline(component)

              expect(page).to have_link 'Reactivate'
              expect(page).to have_link 'Enroll'
            end

            it 'displays details link' do
              render_inline(component)

              expect(page).to have_link 'Details'
            end

            it 'does not display other links' do
              render_inline(component)

              expect(page).to have_no_link 'Resume'
              expect(page).to have_no_link 'Visit'
            end
          end

          describe 'for enrolled users' do
            let(:enrollment) { Course::Enrollment.new(course:, user_id:) }

            it 'displays a link to reactivate the course and a resume link' do
              render_inline(component)

              expect(page).to have_link 'Reactivate'
              expect(page).to have_link 'Resume'
            end

            it 'displays details link' do
              render_inline(component)

              expect(page).to have_link 'Details'
            end

            it 'does not display other links' do
              render_inline(component)

              expect(page).to have_no_link 'Enroll'
              expect(page).to have_no_link 'Visit'
            end
          end

          describe 'for enrolled users who have reactivated the course' do
            let(:enrollment) { Course::Enrollment.new(course:, user_id:, forced_submission_date: 2.weeks.from_now) }

            it 'displays a resume link but does not suggest reactivation' do
              render_inline(component)

              expect(page).to have_no_link 'Reactivate'
              expect(page).to have_link 'Resume'

              expect(page).to have_no_link 'Enroll'
              expect(page).to have_no_link 'Visit'
            end

            it 'displays details link' do
              render_inline(component)

              expect(page).to have_link 'Details'
            end
          end

          describe 'for enrolled users who had reactivated before' do
            let(:enrollment) { Course::Enrollment.new(course:, user_id:, forced_submission_date: 2.weeks.ago) }

            it 'displays a link to reactivate the course and a resume link' do
              render_inline(component)

              expect(page).to have_link 'Reactivate'
              expect(page).to have_link 'Resume'
            end

            it 'displays details link' do
              render_inline(component)

              expect(page).to have_link 'Details'
            end

            it 'does not display other links' do
              render_inline(component)

              expect(page).to have_no_link 'Enroll'
              expect(page).to have_no_link 'Visit'
            end
          end

          describe 'for a compact type card' do
            let(:type) { 'compact' }

            it 'renders the course reactivation button inside the actions dropdown' do
              render_inline(component)
              dropdown = page.find('[data-behaviour="menu-dropdown"]')
              expect(dropdown).to have_link 'Reactivate'
            end
          end
        end

        it 'renders custom additional buttons (if provided as a slot)' do
          render_inline(component) do |c|
            c.with_action { '<a href=#>Extra button</a>'.html_safe }
          end

          expect(page).to have_css '[aria-label="More actions"]'
          expect(page).to have_link 'Show details'
          expect(page).to have_link 'Extra button'
          expect(page).to have_no_link 'Details'
        end
      end
    end
  end

  describe 'date label' do
    context 'with past end date' do
      context 'with status active' do
        let(:course) { create(:course, :active, end_date: 3.months.ago) }

        it 'displays self-paced' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: "Self-paced since #{I18n.l(course.end_date, format: :abbreviated_month_date)}"
        end
      end

      context 'with being archived' do
        let(:course) { create(:course, :archived) }

        it 'displays self-paced' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: "Self-paced since #{I18n.l(course.end_date, format: :abbreviated_month_date)}"
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
          render_inline(component)

          expect(page).to have_no_selector "[aria-label='Course dates']"
        end
      end
    end

    context 'without end date' do
      context 'with past start date' do
        context 'with status active' do
          let(:course) { create(:course, :active, start_date: 3.months.ago, end_date: nil) }

          it 'displays the past start date' do
            render_inline(component)

            expect(page).to have_css "[aria-label='Course dates']", text: "Self-paced since #{I18n.l(course.start_date, format: :abbreviated_month_date)}"
          end
        end

        context 'with being archived' do
          let(:course) { create(:course, :archived, start_date: 3.months.ago, end_date: nil) }

          it 'displays the past start date' do
            render_inline(component)

            expect(page).to have_css "[aria-label='Course dates']", text: "Self-paced since #{I18n.l(course.start_date, format: :abbreviated_month_date)}"
          end
        end
      end

      context 'with future start date' do
        context 'with active status' do
          let(:course) { create(:course, :active, start_date: 3.months.from_now, end_date: nil) }

          it 'displays the future start date' do
            render_inline(component)

            expect(page).to have_css "[aria-label='Course dates']", text: "Beginning #{I18n.l(course.start_date, format: :abbreviated_month_date)}"
          end
        end

        context 'with being archived' do
          let(:course) { create(:course, :archived, start_date: 3.months.from_now, end_date: nil) }

          it 'displays the future start date' do
            render_inline(component)

            expect(page).to have_css "[aria-label='Course dates']", text: "Beginning #{I18n.l(course.start_date, format: :abbreviated_month_date)}"
          end
        end
      end
    end

    context 'with upcoming end date' do
      context 'with active status' do
        let(:course) { create(:course, :active) }

        it 'shows the time range' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: I18n.l(course.start_date, format: :abbreviated_month_date)
          expect(page).to have_css "[aria-label='Course dates']", text: I18n.l(course.end_date, format: :abbreviated_month_date)
        end
      end

      context 'with being archived' do
        let(:course) { create(:course, :archived, end_date: 1.week.from_now) }

        it 'shows the time range' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: I18n.l(course.start_date, format: :abbreviated_month_date)
          expect(page).to have_css "[aria-label='Course dates']", text: I18n.l(course.end_date, format: :abbreviated_month_date)
        end
      end
    end

    context 'without start date nor end date' do
      context 'with active status' do
        let(:course) { create(:course, :active, start_date: nil, end_date: nil) }

        it 'shows no date' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: 'Coming soon'
        end
      end

      context 'with being archive' do
        let(:course) { create(:course, :archived, start_date: nil, end_date: nil) }

        it 'shows no date' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course dates']", text: 'Coming soon'
        end
      end
    end

    context 'with display_start_date' do
      let(:course) { create(:course, :active, display_start_date: 7.days.ago) }

      it 'displays the display_start_date instead of start_date' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Course dates']", text: I18n.l(course.display_start_date, format: :abbreviated_month_date)
      end
    end
  end

  describe 'certificate datapoint' do
    context 'with no certificates available' do
      let(:cop_enabled) { false }
      let(:roa_enabled) { false }
      let(:proctored) { false }
      let(:course) { create(:course, :active, proctored:, roa_enabled:, cop_enabled:) }

      it 'does not display any certificate information' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Highest achievable certificate']", exact_text: ''
      end
    end

    context 'with only confirmation of participation available' do
      let(:cop_enabled) { true }
      let(:roa_enabled) { false }
      let(:proctored) { false }
      let(:course) { create(:course, :active, proctored:, roa_enabled:, cop_enabled:) }

      it 'shows the highest achievable certificate (CoP)' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Highest achievable certificate']", text: 'Confirmation of Participation'
      end
    end

    context 'with Certificate / ECTS available' do
      let(:roa_enabled) { true }
      let(:proctored) { true }
      let(:course) { create(:course, :active, proctored:, roa_enabled:) }

      it 'shows the highest achievable certificate (ECTS)' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Highest achievable certificate']", text: 'Certificate / ECTS'
      end
    end

    context 'with Record of Achievement available and no ECTS' do
      let(:roa_enabled) { true }
      let(:proctored) { false }
      let(:course) { create(:course, :active, proctored:, roa_enabled:) }

      it 'shows the highest achievable certificate (ROA)' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Highest achievable certificate']", text: 'Record of Achievement'
      end
    end
  end

  describe 'language and subtitles metadata' do
    context 'with subtitles available' do
      let(:section) { create(:section, course_id: course.id, published: true) }
      let(:video_item) { create(:item, :video, content_id: video.id, section_id: section.id, content_type: 'video') }
      let(:video) { create(:video) }

      before do
        video_item
        video.subtitles << create(:video_subtitle, lang: 'en')
        video.subtitles << create(:video_subtitle, lang: 'de')
        video.subtitles << create(:video_subtitle, lang: 'fr')
      end

      it 'displays the course language and the number of subtitles available' do
        render_inline(component)

        expect(page).to have_css "[aria-label='Course language and subtitles available']", text: 'en + 3 subtitles'
      end
    end

    context 'with no subtitles available' do
      it 'displays only the course language' do
        render_inline(component)

        # NOTE: We match the *exact* text, to ensure no mention of "subtitles"
        expect(page).to have_css "[aria-label='Course language and subtitles available']", exact_text: 'en'
      end
    end
  end

  describe 'classifiers datapoint' do
    let(:topic) { create(:cluster, id: 'topic') }
    let(:level) { create(:cluster, id: 'level') }

    context 'platform configured with no classifier clusters' do
      before do
        xi_config <<~YML
          course_card:
            classifier_clusters: []
        YML
        course.classifiers << create(:classifier, cluster: topic, title: 'Programming')
      end

      it 'does not display the classifiers even if the course has classifiers' do
        render_inline(component)

        expect(page).to have_no_selector "[aria-label='Course classifiers']"
      end
    end

    context 'platform configured with classifier clusters' do
      before do
        xi_config <<~YML
          course_card:
            classifier_clusters:
              - topic
              - level
        YML
      end

      context 'course with no classifiers' do
        before { topic; level }

        it 'displays the empty state' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course classifiers']", exact_text: ''
        end
      end

      context 'course with topics and level classifiers' do
        before do
          course.classifiers << create(:classifier, cluster: topic, title: 'programming', translations: {en: 'Programming'})
          course.classifiers << create(:classifier, cluster: topic, title: 'databases', translations: {en: 'Databases', de: 'Datenbanken'})
          course.classifiers << create(:classifier, cluster: level, title: 'beginner', translations: {en: 'Beginner', de: 'Anfänger'})
        end

        it 'displays topics before levels as defined in the configuration' do
          render_inline(component)
          expect(page).to have_css "[aria-label='Course classifiers']", text: 'Programming, Databases, Beginner'
        end

        context 'with a different platform language' do
          it 'displays the best translation' do
            I18n.with_locale(:de) do
              render_inline(component)
              expect(page).to have_css "[aria-label='Kurs-Klassifizierung']", text: 'Programming, Datenbanken, Anfänger'
            end
          end

          it "defaults the platform's default language if no translation is provided" do
            I18n.with_locale(:de) do
              render_inline(component)
              expect(page).to have_css "[aria-label='Kurs-Klassifizierung']", text: 'Programming'
            end
          end
        end
      end

      context 'course with classifiers from a different cluster than the configured ones' do
        let(:campaign) { create(:cluster, id: 'campaign') }

        before do
          topic
          level
          course.classifiers << create(:classifier, cluster: campaign, title: 'Summer')
        end

        it 'displays the empty state' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course classifiers']", exact_text: ''
        end
      end

      context 'course with classifier from invisible cluster configured' do
        before do
          invisible = create(:cluster, :invisible, id: 'invisible')
          course.classifiers << create(:classifier, cluster: invisible, title: 'Internal')
          course.classifiers << create(:classifier, cluster: topic, title: 'programming', translations: {en: 'Programming'})

          xi_config <<~YML
            course_card:
              classifier_clusters:
                - topic
                - invisible
          YML
        end

        it 'only displays classifiers from visible clusters' do
          render_inline(component)

          expect(page).to have_css "[aria-label='Course classifiers']", exact_text: 'Programming'
        end
      end
    end
  end
end
