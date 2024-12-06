# frozen_string_literal: true

require 'spec_helper'

describe 'Voucher Redemptions: New', type: :request do
  subject(:get_book) do
    get "/courses/#{course.course_code}/book/#{product_type}", headers:
  end

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML
  end

  let(:headers) { {} }
  let(:request_context_id) { course.context_id }
  let(:page) { Capybara.string(response.body) }

  describe 'proctoring' do
    let(:product_type) { 'proctoring_smowl' }
    let(:course) { create(:course, :upcoming) }

    it 'redirects to the login path when the user is not logged in' do
      expect(get_book).to redirect_to 'http://www.example.com/sessions/new'
    end

    context 'with user logged in' do
      let(:user_id) { generate(:user_id) }
      let!(:user) { stub_user_request id: user_id, permissions: %w[course.content.access] } # rubocop:disable RSpec/LetSetup
      let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

      context 'with proctored course' do
        let(:course) { create(:course, :upcoming, :offers_proctoring) }

        it 'renders the booking page' do
          get_book
          expect(response).to have_http_status :ok

          expect(page).to have_content 'Book a Certificate'
          expect(page).to have_content 'You are going to redeem a voucher for'
          expect(page).to have_content 'MOOC on topic'
          expect(page).to have_button 'Redeem'
        end
      end

      context 'with non-proctored course' do
        it 'redirects to the course path' do
          expect(get_book).to redirect_to course_path(course.course_code)
        end
      end
    end
  end

  describe 'reactivation' do
    let(:product_type) { 'course_reactivation' }
    let(:course) { create(:course, :archived) }

    it 'redirects to the login path when the user is not logged in' do
      expect(get_book).to redirect_to 'http://www.example.com/sessions/new'
    end

    context 'with user logged in' do
      let(:user_id) { generate(:user_id) }
      let!(:user) { stub_user_request id: user_id, features: {'course_reactivation' => true}, permissions: %w[course.content.access] } # rubocop:disable RSpec/LetSetup
      let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

      context 'when the course offers reactivation' do
        let(:course) { create(:course, :archived, :offers_reactivation) }

        it 'renders the booking page when the course has finished' do
          get_book
          expect(response).to have_http_status :ok

          expect(page).to have_content 'Reactivate this course'
          expect(page).to have_content 'purchase a voucher code for the course reactivation'
          expect(page).to have_content 'You are going to redeem a voucher for'
          expect(page).to have_content 'MOOC on topic'
          expect(page).to have_button 'Redeem'
        end

        context 'but is in preparation' do
          let(:course) { create(:course, :preparing, :offers_reactivation) }

          it 'redirects to the course path' do
            expect(get_book).to redirect_to course_path(course.course_code)
          end
        end

        context 'but has not yet started' do
          let(:course) { create(:course, :upcoming, :offers_reactivation) }

          it 'redirects to the course path' do
            expect(get_book).to redirect_to course_path(course.course_code)
          end
        end

        context 'but has not yet ended' do
          let(:course) { create(:course, :active, :offers_reactivation) }

          it 'redirects to the course path' do
            expect(get_book).to redirect_to course_path(course.course_code)
          end
        end
      end

      context 'when the course does not offer reactivation' do
        it 'redirects to the course path' do
          expect(get_book).to redirect_to course_path(course.course_code)
        end
      end
    end
  end
end
