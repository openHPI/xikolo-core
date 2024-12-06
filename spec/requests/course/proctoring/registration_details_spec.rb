# frozen_string_literal: true

require 'spec_helper'

describe 'Proctoring: Registration details', type: :request do
  subject(:get_details) do
    get '/courses/the-course/proctoring/registration_details', headers:
  end

  let(:headers) { {} }
  let(:request_context_id) { course.context_id }
  let(:course) { create(:course, :active, course_code: 'the-course') }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML
  end

  it 'redirects to the login path when the user is not logged in' do
    expect(get_details).to redirect_to 'http://www.example.com/sessions/new'
  end

  context 'with user logged in' do
    let(:user_id) { generate(:user_id) }
    let!(:user) { stub_user_request id: user_id, permissions: %w[course.content.access] } # rubocop:disable RSpec/LetSetup
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

    context 'with proctored course' do
      let(:course) { create(:course, :active, :offers_proctoring, course_code: 'the-course') }

      context 'with upgraded enrollment' do
        before do
          create(:enrollment, :proctored, course:, user_id:)

          allow(Proctoring::SmowlAdapter).to receive(:new).and_return(
            instance_double(
              Proctoring::SmowlAdapter,
              registration_status: Proctoring::RegistrationStatus.new(registration_status)
            )
          )
        end

        context 'with user registered with SMOWL' do
          let(:registration_status) { :complete }

          it 'redirects to the course path' do
            expect(get_details).to redirect_to '/courses/the-course'
          end
        end

        context 'with user not registered with SMOWL' do
          let(:page) { Capybara.string(response.body) }
          let(:registration_status) { :required }

          it 'renders the registration details' do
            get_details
            expect(response).to have_http_status :ok

            expect(page).to have_content 'Calibration for the Certificate'
            expect(page).to have_content 'Calibrate your image as soon as possible'
            expect(page).to have_link(
              'Calibrate your image',
              href: '/courses/the-course/proctoring/register_at_smowl'
            )
          end
        end
      end

      context 'with enrollment not yet upgraded' do
        before { create(:enrollment, course:, user_id:) }

        it 'redirects to the course path' do
          expect(get_details).to redirect_to '/courses/the-course'
        end
      end
    end

    context 'with non-proctored course' do
      it 'redirects to the course path' do
        expect(get_details).to redirect_to '/courses/the-course'
      end
    end
  end
end
