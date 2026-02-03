# frozen_string_literal: true

require 'spec_helper'

describe LearningModeController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:features) { {} }

  before do
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      status: 'active',
      title: 'Title',
      course_code: 'course_code',
      context_id: request_context_id,
    })
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:}
    ).to_return Stub.json([
      {id: SecureRandom.uuid},
    ])
  end

  describe '#index' do
    subject(:index) { get :index, params: {course_id:} }

    let(:request_context_id) { course_context_id }

    context 'anonymous' do
      it { is_expected.to have_http_status :found }
    end

    context 'with user' do
      before do
        stub_user id: user_id,
          permissions: ['course.content.access.available'],
          features:
      end

      it 'responds with 404 Not Found when the quiz recap is not enabled' do
        expect { index }.to raise_error AbstractController::ActionNotFound
      end

      context 'with quiz_recap feature enabled' do
        let(:features) { {'quiz_recap' => true} }

        it { is_expected.to have_http_status :ok }
      end
    end
  end

  describe '#review' do
    subject(:action) { get :review, params: }

    let(:params) { {} }
    let(:item_id) { SecureRandom.uuid }
    let(:prev_item_id) { SecureRandom.uuid }
    let(:quiz_id) { SecureRandom.uuid }
    let(:item_response) { Stub.json({id: item_id}) }

    before do
      Stub.request(
        :course, :get, '/items',
        query: {content_id: quiz_id}
      ).to_return Stub.json([
        {id: item_id},
      ])
      Stub.request(
        :course, :get, "/items/#{item_id}"
      ).to_return item_response

      stub_user id: user_id, permissions: ['course.content.access.available']
    end

    context 'without params' do
      it { is_expected.to redirect_to learn_path }

      it 'sets an error flash message' do
        action
        expect(flash[:error].first).to eq I18n.t(:'flash.error.params_missing_learn_review')
      end
    end

    context 'with params' do
      let(:params) { {quiz_id:, course_id:} }
      let(:request_context_id) { course_context_id }

      it { is_expected.to redirect_to course_item_path(id: item_id, course_id:) }

      context 'with prev_item_id' do
        let(:item_response) { Stub.json({id: item_id, prev_item_id:}) }

        it { is_expected.to redirect_to course_item_path(id: prev_item_id, course_id:) }
      end
    end
  end
end
