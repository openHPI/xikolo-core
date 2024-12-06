# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Progress', type: :request do
  subject(:show_progress) do
    get "/courses/#{course.course_code}/progress", headers:
  end

  let(:headers) { {} }
  let(:request_context_id) { course_resource['context_id'] }
  let(:course) { create(:course, title: 'My Awesome Course', records_released: true) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code,
      title: 'My Awesome Course',
      records_released: true,
      context_id: generate(:context_id))
  end
  let(:progresses) { build(:'course:progresses') }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .and_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects the user' do
      show_progress
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end

  context 'for logged-in user' do
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }
    let(:user_id) { generate(:user_id) }
    let(:enrollments) { [] }
    let(:permissions) { [] }
    let(:features) { {} }
    let(:page) { Capybara.string(response.body) }

    before do
      stub_user_request(id: user_id, permissions:, features:)

      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, learning_evaluation: true, user_id:}
      ).and_return Stub.json(enrollments)
      Stub.request(
        :course, :get, '/progresses',
        query: {course_id: course.id, user_id:}
      ).and_return Stub.json(progresses)
      Stub.request(:course, :get, '/next_dates', query: hash_including({}))
        .to_return Stub.json([])
    end

    it 'redirects the user if not enrolled' do
      show_progress
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end

    context 'when the user is enrolled in the course' do
      let(:permissions) { %w[course.content.access.available] }
      let(:enrollments) do
        [build(:'course:enrollment', course_id: course.id, user_id:, certificates:)]
      end
      let(:certificates) do
        {
          record_of_achievement: false,
          confirmation_of_participation: false,
          certificate: false,
        }
      end

      before do
        Stub.request(:course, :get, "/courses/#{course.id}")
          .and_return Stub.json(course_resource)
      end

      it 'displays the course progress page' do
        show_progress
        expect(response.body).to include 'My course certificates'
      end

      context 'when the learner dashboard is enabled' do
        let(:features) { {'learner_dashboard' => true} }

        it 'displays the course progress page' do
          show_progress
          expect(response.body).to include 'My course certificates'
        end
      end

      context 'when the user has started a course but not completed yet' do
        let(:certificates) do
          {
            record_of_achievement: false,
            confirmation_of_participation: true,
            certificate: false,
          }
        end

        before do
          create(:certificate_template, :cop, course:)
          create(:certificate_template, :roa, course:)
        end

        it "shows a 'Confirmation of Participation' download link only" do
          show_progress
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_link('Confirmation of Participation', href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
          expect(page).to have_button('Record of Achievement', disabled: true)
          expect(page).to have_no_button('Certificate')
        end
      end

      context 'when the user has unenrolled from the course but has achieved a certificate' do
        let(:enrollments) do
          [build(:'course:enrollment', :deleted, course_id: course.id, user_id:, certificates:)]
        end
        let(:certificates) do
          {
            record_of_achievement: false,
            confirmation_of_participation: true,
            certificate: false,
          }
        end

        before do
          create(:certificate_template, :cop, course:)
        end

        it "still shows a 'Confirmation of Participation' download link" do
          show_progress
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_link('Confirmation of Participation', href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
          expect(page).to have_no_button('Record of Achievement')
          expect(page).to have_no_button('Certificate')
        end
      end

      context 'when the user has completed a course with RoA' do
        let(:certificates) do
          {
            record_of_achievement: true,
            confirmation_of_participation: true,
            certificate: false,
          }
        end

        before do
          create(:certificate_template, :roa, course:)
          create(:certificate_template, :cop, course:)
          create(:open_badge_template, course:)
        end

        it 'shows the correct certificate requirements information' do
          show_progress
          expect(page).to have_content('Gain a Record of Achievement by earning at least 50% of the maximum number of points from all graded assignments.')
          expect(page).to have_content('Gain a Confirmation of Participation by completing at least 50% of the course material.')
          expect(page).to have_no_content('Gain a Transcript of Records by fulfilling all requirements for this course.')
          expect(page).to have_content('Gain an Open Badge by completing the course.')
        end

        it "shows a 'Record of Achievement' download link" do
          show_progress
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_no_button('Record of Achievement')
          expect(page).to have_link('Record of Achievement', href: "/certificate/render?course_id=#{course.id}&type=RecordOfAchievement")
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_link('Confirmation of Participation', href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
          expect(page).to have_no_button('Certificate')
        end
      end

      context 'when the user has completed a course with ToR' do
        let(:certificates) do
          {
            record_of_achievement: false,
            confirmation_of_participation: false,
            certificate: false,
            transcript_of_records: true,
          }
        end

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

          create(:certificate_template, :tor, course:)
        end

        it 'shows the correct certificate requirements information' do
          show_progress
          expect(page).to have_no_content('Gain a Record of Achievement by earning at least 50% of the maximum number of points from all graded assignments.')
          expect(page).to have_no_content('Gain a Confirmation of Participation by completing at least 50% of the course material.')
          expect(page).to have_content('Gain a Transcript of Records by fulfilling all requirements for this course.')
          expect(page).to have_no_content('Gain an Open Badge by completing the course.')
        end

        it "shows a 'Transcript of Records' download link" do
          show_progress
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_no_button('Record of Achievement')
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_no_button('Certificate')
          expect(page).to have_no_button('Transcript of Records')
          expect(page).to have_link('Transcript of Records', href: "/certificate/render?course_id=#{course.id}&type=TranscriptOfRecords")
        end
      end

      context 'when a user has finished a course with proctoring' do
        let(:enrollments) do
          [build(:'course:enrollment', :proctored, course_id: course.id, user_id:, certificates:)]
        end
        let(:features) { {'proctoring' => 'true'} }
        let(:certificates) do
          {
            record_of_achievement: true,
            confirmation_of_participation: true,
            certificate: true,
          }
        end

        before do
          create(:certificate_template, :certificate, course:)
          create(:certificate_template, :roa, course:)
          create(:certificate_template, :cop, course:)
          allow(Proctoring::SmowlAdapter).to receive(:new).and_wrap_original do |m, *args|
            m.call(*args).tap do |adapter|
              allow(adapter).to receive(:passed?).and_return(true)
            end
          end
        end

        it 'shows CoP, RoA and Certificate download links' do
          show_progress
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_no_button('Record of Achievement')
          expect(page).to have_link('Record of Achievement', href: "/certificate/render?course_id=#{course.id}&type=RecordOfAchievement")
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_link('Confirmation of Participation', href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
          expect(page).to have_no_button('Certificate')
          expect(page).to have_link('Certificate', href: "/certificate/render?course_id=#{course.id}&type=Certificate")
        end
      end
    end
  end
end
