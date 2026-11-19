# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Course management: Submissions', type: :request do
  subject(:list_submissions) { get "/learn/#{course.id}/submissions" }

  let(:page) { Capybara.string(response.body) }
  let(:course) { create(:'course_service/course') }

  context 'for anonymous users' do
    it 'redirects the user' do
      list_submissions
      expect(response).to have_http_status :see_other
      expect(response).to redirect_to("http://www.example.com/learn/#{course.course_code}")
      # As the user is not logged in, they are redirected to the course home page.
      # If they would be logged in they would be redirected to root with You do not have sufficient permissions for this action.
    end
  end

  context 'for logged-in users' do
    let(:user) { create(:'account_service/user', :gdpr_admin) }

    before do
      sign_in(user:)
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      it 'redirects the user' do
        list_submissions
        expect(response).to have_http_status :see_other
      end
    end

    context 'with permissions' do
      let(:submission_user) { create(:'account_service/user') }
      let!(:submission) do
        create(:'quiz_service/quiz_submission',
          course_id: course.id,
          user_id: submission_user.id,
          quiz_submission_time: 1.hour.ago)
      end

      before do
        if submission
          section = create(:'course_service/section',
            course: create(:'course_service/course', skip_account_groups: true))
          create(:'course_service/item', :quiz, content_id: submission.quiz_id, section:)
        end
        sign_in(user:)
      end

      it 'renders the submissions list' do
        list_submissions
        expect(response).to have_http_status :ok
        expect(page).to have_text(submission.id)
        expect(page).to have_text(submission.quiz_id)
        expect(page).to have_text(submission_user.display_name)
        expect(page).to have_text(submission.item.title)
      end

      context 'when the course has no submissions' do
        let(:submission) { nil }

        it 'renders the empty state' do
          list_submissions
          expect(response).to have_http_status :ok
          expect(page).to have_text('It looks like there are no quiz submissions in this course so far.')
        end
      end
    end
  end
end
