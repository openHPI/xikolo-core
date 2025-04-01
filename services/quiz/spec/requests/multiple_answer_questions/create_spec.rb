# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multiple Answer Questions: Create', type: :request do
  subject(:resource) { api.rel(:multiple_answer_questions).post(payload).value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:payload) { attributes_for(:multiple_answer_question, quiz_id: quiz.id) }
  let(:quiz) { create(:quiz) }

  before do
    Stub.service(
      :course,
      items_url: 'http://course.xikolo.tld/items',
      item_url: 'http://course.xikolo.tld/items/{id}'
    )
    Stub.request(
      :course, :get, '/items',
      query: {content_id: payload[:quiz_id]}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918'},
    ])
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: payload[:points])
    ).to_return Stub.json({max_points: payload[:points]})
  end

  it { is_expected.to respond_with :created }

  it 'creates a new multiple answer question' do
    expect { resource }.to change(MultipleAnswerQuestion, :count).from(0).to(1)
  end

  context 'without a type attribute' do
    let(:payload) { super().except(:type) }

    it 'creates a new multiple answer question' do
      expect { resource }.to change(MultipleAnswerQuestion, :count).from(0).to(1)
    end
  end
end
