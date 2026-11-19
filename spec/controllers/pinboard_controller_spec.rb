# frozen_string_literal: true

require 'spec_helper'

describe PinboardController, type: :controller do
  let(:course_id) { SecureRandom.uuid }
  let(:user) { create(:'account_service/user') }
  let(:permissions) { ['course.content.access.available'] }
  let(:course_context) { AccountService::Context.root }
  let(:course) { create(:'course_service/course', id: course_id, context_id: course_context.id, pinboard_enabled: true) }

  before do
    course
  end

  describe 'index' do
    context 'not logged in' do
      it 'redirects' do
        get :index, params: {course_id:}
        expect(response).to have_http_status :found
      end
    end

    context 'logged in' do
      before { sign_in user: user, permissions: }

      context 'with disabled pinboard' do
        let(:course) { create(:'course_service/course', id: course_id, context_id: course_context.id, pinboard_enabled: false) }

        it 'raises an error' do
          expect do
            get :index, params: {course_id:}
          end.to raise_error(AbstractController::ActionNotFound)
        end
      end

      context 'with a published, available section' do
        let!(:section) { create(:'course_service/section', course:, published: true) }

        it 'lists the section as a discussion filter option' do
          get :index, params: {course_id:}

          expect(response).to have_http_status :ok
          expect(assigns(:pinboard).section_filter.map(&:first)).to include(section.title)
        end
      end
    end
  end
end
