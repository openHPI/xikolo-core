# frozen_string_literal: true

require 'spec_helper'

describe 'Voucher Redemptions: New', type: :request do
  subject(:get_book) do
    get "/learn/#{course.course_code}/book/#{product_type}"
  end

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML
  end

  let(:request_context_id) { course.context_id }
  let(:course_context) { create(:'account_service/context') }
  let(:page) { Capybara.string(response.body) }

  describe 'reactivation' do
    let(:product_type) { 'course_reactivation' }
    let(:course) { create(:course, :self_paced, context_id: course_context.id) }

    it 'redirects to the login path when the user is not logged in' do
      expect(get_book).to redirect_to 'http://www.example.com/sessions/new'
    end

    context 'with user logged in' do
      let(:user) { create(:'account_service/user') }
      let(:user_id) { user.id }
      let(:permissions) { %w[course.content.access] }

      before do
        sign_in(user:)
        role = create(:'account_service/role', permissions:)
        create(:'account_service/grant', principal: user, role:, context: course_context)
        user.features.create(name: 'course_reactivation', value: 'true', context: AccountService::Context.root)
      end

      context 'when the course offers reactivation' do
        let(:course) { create(:course, :self_paced, :offers_reactivation, context_id: course_context.id) }

        it 'renders the booking page when the course has finished' do
          get_book
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Reactivate this course'
          expect(page).to have_text 'received a reactivation-code for the course reactivation'
          expect(page).to have_text 'You are going to redeem a voucher for'
          expect(page).to have_text 'MOOC on topic'
          expect(page).to have_button 'Redeem'
        end

        context 'but is in preparation' do
          let(:course) { create(:course, :preparing, :offers_reactivation, context_id: course_context.id) }

          it 'redirects to the course path' do
            expect(get_book).to redirect_to course_path(course.course_code)
          end
        end

        context 'but has not yet started' do
          let(:course) { create(:course, :upcoming, :offers_reactivation, context_id: course_context.id) }

          it 'redirects to the course path' do
            expect(get_book).to redirect_to course_path(course.course_code)
          end
        end

        context 'but has not yet ended' do
          let(:course) { create(:course, :active, :offers_reactivation, context_id: course_context.id) }

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
