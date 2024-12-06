# frozen_string_literal: true

require 'spec_helper'

describe 'Proctoring: Register at SMOWL', type: :request do
  subject(:get_register) do
    get '/courses/the-course/proctoring/register_at_smowl', headers:
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
    expect(get_register).to redirect_to 'http://www.example.com/sessions/new'
  end

  context 'with user logged in' do
    let(:user_id) { '00000001-3100-4444-9999-000000000001' }
    let(:pseudonymized_user_id) { '35d6e0fba8a2afceba2d80ff7f6b879b80b1f2c68eea10e30ee30ddae868469d' }
    let!(:user) { stub_user_request id: user_id, permissions: %w[course.content.access] } # rubocop:disable RSpec/LetSetup
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

    context 'with proctored course' do
      let(:course) { create(:course, :active, :offers_proctoring, course_code: 'the-course') }

      context 'with upgraded enrollment' do
        before do
          create(:enrollment, :proctored, course:, user_id:)

          allow(Proctoring::SmowlAdapter).to receive(:new).and_wrap_original do |m, *args|
            m.call(*args).tap do |adapter|
              allow(adapter).to receive(:registration_status).and_return(
                Proctoring::RegistrationStatus.new(registration_status)
              )
            end
          end
        end

        context 'with user registered with SMOWL' do
          let(:registration_status) { :complete }

          it 'redirects to the course path' do
            expect(get_register).to redirect_to '/courses/the-course'
          end
        end

        context 'with user not registered with SMOWL' do
          let(:registration_status) { :required }

          it 'redirects to the SMOWL registration page' do
            expect(get_register).to redirect_to(
              'https://swl.smowltech.net/monitor/controllerReg.php?' \
              'entity_Name=SampleEntity' \
              '&swlLicenseKey=samplekey' \
              "&user_idUser=#{pseudonymized_user_id}" \
              '&lang=en' \
              '&Course_link=http%3A%2F%2Fwww.example.com%2Fcourses%2Fthe-course'
            )
          end
        end
      end

      context 'with enrollment not yet upgraded' do
        before { create(:enrollment, course:, user_id:) }

        it 'redirects to the course path' do
          expect(get_register).to redirect_to '/courses/the-course'
        end
      end
    end

    context 'with non-proctored course' do
      it 'redirects to the course path' do
        expect(get_register).to redirect_to '/courses/the-course'
      end
    end
  end
end
