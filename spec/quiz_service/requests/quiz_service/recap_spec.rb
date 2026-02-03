# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recap: Load questions for recap', type: :request do
  subject { api.rel(:questions).get({**params, selftests: true}).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }
  let(:params) { {} }
  let(:item_params) do
    {
      all_available: true,
      content_type: 'quiz',
      exercise_type: 'selftest',
      course_id: nil,
      required_items: 'none',
      per_page: 250,
    }
  end

  # Create a quiz with two questions: an empty one and one with two answers
  let!(:quiz) do
    create(:'quiz_service/quiz').tap do |quiz|
      create_list(:'quiz_service/multiple_choice_question', 2, quiz_id: quiz.id)

      create(:'quiz_service/multiple_choice_question', quiz_id: quiz.id).tap do |question|
        create_list(:'quiz_service/answer', 2, question:)
      end
    end
  end

  # Create a second quiz with one question that has four answers
  let!(:quiz2) do
    create(:'quiz_service/quiz').tap do |quiz2|
      create(:'quiz_service/multiple_choice_question', quiz_id: quiz2.id).tap do |question|
        create_list(:'quiz_service/answer', 4, question:)
      end
    end
  end

  before do
    Stub.request(
      :course, :get, '/items',
      query: item_params
    ).to_return Stub.json([
      {content_id: quiz.id},
      {content_id: quiz2.id},
    ])
  end

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(2).items }
  it { is_expected.to all include('text', 'answers') }

  context 'with given course_id' do
    let(:params) { super().merge(course_id: SecureRandom.uuid) }

    before do
      Stub.request(
        :course, :get, '/items',
        query: item_params.merge(course_id: params[:course_id])
      ).to_return Stub.json([{content_id: quiz2.id}])
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to have(1).item }
    it { is_expected.to all include('text', 'answers') }
  end
end
