# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Enrollments: List', type: :request do
  subject(:list_enrollments) { get "/learn/#{course.id}/enrollments" }

  let(:page) { Capybara.string(response.body) }
  let(:course) { create(:'course_service/course') }

  context 'for anonymous users' do
    it 'redirects the user' do
      list_enrollments
      expect(response).to have_http_status :see_other
    end
  end

  context 'for logged in users' do
    let(:user) { create(:'account_service/user', :admin) }

    before do
      sign_in(user:)
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects the user' do
        list_enrollments
        expect(response).to have_http_status :see_other
      end
    end

    context 'with permissions' do
      context 'when the course has no enrollments' do
        it 'renders the enrollments page with no enrollments' do
          list_enrollments
          expect(response).to render_template :index
          expect(page).to have_no_text 'Enrolled'
        end
      end

      context 'when the course has enrollments' do
        before { create(:enrollment, course:, user:) }

        it 'renders the enrollments page with the enrollments' do
          list_enrollments
          expect(response).to render_template :index
          expect(page).to have_text 'Enrolled'
          expect(page).to have_text user.full_name
          expect(page).to have_text user.email
        end

        it 'does not show a reactivation feature' do
          list_enrollments
          expect(page).to have_no_text 'Reactivation'
        end
      end

      context 'when an enrollment has been reactivated' do
        let(:submission_date) { 3.weeks.from_now }

        before { create(:enrollment, course:, user:, forced_submission_date: submission_date) }

        it 'shows the reactivation feature with the submission date' do
          list_enrollments
          expect(page).to have_text 'Reactivation'
          expect(page).to have_css("span[title='Until #{I18n.l(submission_date, format: :short)}']")
        end
      end
    end
  end
end
