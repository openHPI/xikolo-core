# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Statistics: Index: most_active', type: :request do
  subject(:response) do
    api.rel(:statistics).get({
      most_active: 2,
      course_id:,
    }).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:first_user_id) { generate(:user_id) }
  let(:second_user_id) { generate(:user_id) }
  let(:course_id) { generate(:course_id) }

  before do
    # first user posts twice in course forum
    first_question = create(:question, user_id: first_user_id, course_id:)
    create(:answer, user_id: first_user_id, question_id: first_question.id)
    second_question = create(:question, user_id: first_user_id, course_id:)
    create(:answer, user_id: first_user_id, question_id: second_question.id)

    # second user posts once in course forum
    third_question = create(:question, user_id: second_user_id, course_id:)
    create(:answer, user_id: second_user_id, question_id: third_question.id)

    Stub.service(:course, course_url: '/courses/{id}')
    Stub.service(:account, user_url: '/users/{id}')
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({id: course_id, special_groups: []})
    Stub.request(:account, :get, "/users/#{first_user_id}")
      .to_return Stub.json({id: first_user_id})
    Stub.request(:account, :get, "/users/#{second_user_id}")
      .to_return Stub.json({id: second_user_id})
  end

  describe 'statistic' do
    it 'returns both users, first user first' do
      expect(response.size).to eq 2
      expect(response[0]['user']['id']).to eq first_user_id
      expect(response[1]['user']['id']).to eq second_user_id
    end
  end
end
