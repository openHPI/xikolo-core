# frozen_string_literal: true

require 'spec_helper'

describe Admin::TeachersController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:teacher_id) { SecureRandom.uuid }
  let(:teacher) { create(:'course_service/teacher', id: teacher_id) }
  let(:course) { create(:'course_service/course', teacher_ids: [teacher_id]) }
  let(:user) { create(:'account_service/user', id: user_id) }
  let(:permissions) { [] }

  before do
    teacher
    sign_in(user:, permissions:)
  end

  describe '#destroy' do
    subject(:action) { -> { delete :destroy, params: {id: teacher_id} } }

    context 'without permission' do
      it 'redirects to root' do
        action.call
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      let(:permissions) { ['course.teacher.manage'] }

      context 'when teacher can be deleted' do
        it 'redirects to index with success message' do
          action.call

          expect(response).to redirect_to teachers_path
          expect(flash[:success]).to include('Teacher was deleted successfully.')
        end
      end

      context 'when teacher is still referenced in courses' do
        before do
          course # create course with teacher reference
        end

        it 'redirects to index with error message' do
          action.call

          expect(response).to redirect_to teachers_path
          expect(flash[:error]).to include('The teacher was not deleted.')
        end
      end
    end
  end
end
