# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::UserStatisticsController, type: :controller do
  routes { PinboardService::Engine.routes }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:user_id) { SecureRandom.uuid }

  describe 'GET show' do
    subject do
      get :show, params: {user_id:}
      json
    end

    describe 'accepted answers by user' do
      before do
        # accepted by user
        question = create(:'pinboard_service/question')
        answer = create(:'pinboard_service/answer', question_id: question.id, user_id:)
        question.update! accepted_answer: answer
        # accepted by others
        create_list(:'pinboard_service/question_with_accepted_answer', 10)
      end

      its(['accepted_answers']) { is_expected.to be 1 }
    end

    describe 'votes given' do
      before do
        # votes by user, 5 for questions, 10 for answers, value sum is 5
        create_list(:'pinboard_service/vote', 5, user_id:, value: -1)
        create_list(:'pinboard_service/vote', 10, :for_answer, user_id:)
        # votes by others
        create_list(:'pinboard_service/vote', 5)
        create_list(:'pinboard_service/vote', 5, :for_answer)
      end

      its(['vote_values_given']) { is_expected.to be 5 }
    end

    describe 'votes received' do
      before do
        question = create(:'pinboard_service/question', user_id:)
        answer = create(:'pinboard_service/answer', user_id:)

        # 5 upvotes and 3 downvotes each -> 4
        create_list(:'pinboard_service/vote', 5, votable_id: question.id, value: 1)
        create_list(:'pinboard_service/vote', 3, votable_id: question.id, value: -1)

        create_list(:'pinboard_service/vote', 5, :for_answer,
          votable_id: answer.id,
          value: 1)
        create_list(:'pinboard_service/vote', 3, :for_answer,
          votable_id: answer.id,
          value: -1)
      end

      its(['vote_values_received']) { is_expected.to be 4 }
    end
  end
end
