# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Documents: Index', type: :request do
  subject(:show_certificates) { get '/dashboard/documents', headers: }

  let(:page) { Capybara.string(response.body) }
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:features) { {} }
  let(:enrollments) { [] }
  let(:preferences) { {properties: {}} }

  before do
    stub_user_request(id: user_id, features:)

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, learning_evaluation: true, deleted: true}
    ).to_return Stub.json(enrollments)
    Stub.request(
      :account, :get, "/users/#{user_id}/preferences"
    ).to_return Stub.json(preferences)
  end

  it 'shows an empty state without any course enrollments' do
    show_certificates
    expect(response.body).to include 'My certificates'
    expect(response.body).to include 'There are no certificates available yet.'
  end

  it 'shows a date of birth preference switch' do
    show_certificates
    expect(page).to have_field('Show date of birth on my certificates', checked: false)
  end

  context 'with date of birth preference' do
    let(:preferences) { {properties: {'records.show_birthdate': 'true'}} }

    it 'shows a date of birth preference switch' do
      show_certificates
      expect(page).to have_field('Show date of birth on my certificates', checked: true)
    end
  end

  context 'with course enrollments' do
    let(:course) do
      create(:course, course_code: 'my-course', title: 'My Awesome Course', records_released: true)
    end
    let(:course_resource) do
      build(:'course:course',
        id: course.id,
        course_code: course.course_code,
        title: course.title,
        records_released: true)
    end
    let(:enrollment) { create(:enrollment, course:, user_id:) }
    let(:enrollments) do
      [
        build(:'course:enrollment',
          course_id: enrollment.course_id,
          user_id: enrollment.user_id,
          certificates:),
      ]
    end

    before do
      Stub.request(:course, :get, "/courses/#{course.id}")
        .to_return Stub.json(course_resource)
    end

    context 'when a user has not achieved any certificate' do
      let(:certificates) do
        {
          record_of_achievement: false,
          confirmation_of_participation: false,
          certificate: false,
        }
      end

      it 'does not show any certificates' do
        show_certificates
        expect(page).to have_content('My certificates')
        expect(page).to have_content('There are no certificates available yet.')
        expect(page).to have_no_content('My Awesome Course')
        expect(page).to have_no_button('Record of Achievement')
        expect(page).to have_no_button('Confirmation of Participation')
        expect(page).to have_no_button('Certificate')
      end
    end

    context 'when a user has achieved a CoP for a course' do
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

      it "shows a 'Confirmation of Participation' download link & a disabled RoA button" do
        show_certificates
        expect(page).to have_content('My certificates')
        expect(page).to have_content('My Awesome Course')
        expect(page).to have_content('(my-course)')
        expect(page).to have_no_button('Confirmation of Participation')
        expect(page).to have_link('Confirmation of Participation',
          href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
        expect(page).to have_button('Record of Achievement', disabled: true)
        expect(page).to have_no_button('Certificate')
      end
    end

    context 'when a user has unenrolled from the course but has achieved a certificate' do
      let(:enrollment) { create(:enrollment, :deleted, course:, user_id:) }
      let(:enrollments) do
        [
          build(:'course:enrollment', :deleted,
            course_id: enrollment.course_id,
            user_id: enrollment.user_id,
            certificates:),
        ]
      end
      let(:certificates) do
        {
          record_of_achievement: false,
          confirmation_of_participation: true,
          certificate: false,
        }
      end

      before { create(:certificate_template, :cop, course:) }

      it "still shows a 'Confirmation of Participation' download link" do
        show_certificates
        expect(page).to have_content('My certificates')
        expect(page).to have_content('My Awesome Course')
        expect(page).to have_content('(my-course)')
        expect(page).to have_no_button('Confirmation of Participation')
        expect(page).to have_link('Confirmation of Participation',
          href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
        expect(page).to have_no_button('Record of Achievement')
        expect(page).to have_no_button('Certificate')
      end
    end

    context 'when a user has finished a course with RoA' do
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
      end

      it "shows a 'Record of Achievement' download link" do
        show_certificates
        expect(page).to have_content('My certificates')
        expect(page).to have_content('My Awesome Course')
        expect(page).to have_content('(my-course)')
        expect(page).to have_no_button('Confirmation of Participation')
        expect(page).to have_link('Confirmation of Participation',
          href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
        expect(page).to have_no_button('Record of Achievement')
        expect(page).to have_link('Record of Achievement',
          href: "/certificate/render?course_id=#{course.id}&type=RecordOfAchievement")
        expect(page).to have_no_button('Certificate')
      end

      context 'when a user has finished a course with proctoring' do
        let(:features) { {'proctoring' => 'true'} }
        let(:enrollment) { create(:enrollment, :proctored, course:, user_id:) }
        let(:enrollments) do
          [
            build(:'course:enrollment', :proctored,
              course_id: enrollment.course_id,
              user_id: enrollment.user_id,
              certificates:),
          ]
        end
        let(:certificates) do
          {
            record_of_achievement: true,
            confirmation_of_participation: true,
            certificate: true,
          }
        end

        before do
          create(:certificate_template, :certificate, course:)
          allow(Proctoring::SmowlAdapter).to receive(:new).and_wrap_original do |m, *args|
            m.call(*args).tap do |adapter|
              allow(adapter).to receive(:passed?).and_return(true)
            end
          end
        end

        it 'shows CoP, RoA and Certificate download links' do
          show_certificates
          expect(page).to have_content('My certificates')
          expect(page).to have_content('My Awesome Course')
          expect(page).to have_content('(my-course)')
          expect(page).to have_no_button('Confirmation of Participation')
          expect(page).to have_link('Confirmation of Participation',
            href: "/certificate/render?course_id=#{course.id}&type=ConfirmationOfParticipation")
          expect(page).to have_no_button('Certificate')
          expect(page).to have_no_button('Record of Achievement')
          expect(page).to have_link('Record of Achievement',
            href: "/certificate/render?course_id=#{course.id}&type=RecordOfAchievement")
          expect(page).to have_no_button('Certificate')
          expect(page).to have_link('Certificate',
            href: "/certificate/render?course_id=#{course.id}&type=Certificate")
        end
      end
    end
  end

  context 'as anonymous user' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      show_certificates
      expect(request).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
