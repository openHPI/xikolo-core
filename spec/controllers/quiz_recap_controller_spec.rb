# frozen_string_literal: true

require 'spec_helper'

describe QuizRecapController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:user) { create(:'account_service/user', id: user_id) }
  let(:course_id) { SecureRandom.uuid }
  let(:course) { create(:'course_service/course', id: course_id, course_code: 'the_course') }
  let(:request_context) { AccountService::Context.root }

  before do
    course
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:}
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
    ])
  end

  describe '#index' do
    subject(:index) { get :index, params: {course_id:} }

    context 'anonymous' do
      it { is_expected.to have_http_status :found }
    end

    context 'with user' do
      before do
        sign_in user: user,
          permissions: ['course.content.access.available']
      end

      it 'responds with http status ok' do
        expect { index }.not_to raise_error
      end
    end
  end

  describe '#review' do
    subject(:action) { get :review, params: }

    let(:params) { {} }
    let(:section) { create(:'course_service/section', course:) }
    let(:quiz_id) { SecureRandom.uuid }

    before do
      sign_in user: user, permissions: ['course.content.access.available']
    end

    context 'without params' do
      it { is_expected.to redirect_to recap_path }

      it 'sets an error flash message' do
        action
        expect(flash[:error].first).to eq I18n.t(:'flash.error.params_missing_learn_review')
      end
    end

    context 'with params' do
      let(:params) { {quiz_id:, course_id:} }
      let!(:item) { create(:'course_service/item', :quiz, section:, content: create(:'quiz_service/quiz', id: quiz_id)) }

      it { is_expected.to redirect_to course_item_path(id: item.id, course_id:) }

      context 'with a preceding item in the section' do
        let!(:prev_item) { create(:'course_service/item', section:).tap(&:move_to_top) }

        it { is_expected.to redirect_to course_item_path(id: prev_item.id, course_id:) }
      end
    end
  end
end
