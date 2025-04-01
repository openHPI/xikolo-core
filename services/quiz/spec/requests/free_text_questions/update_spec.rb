# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Free Text Questions: Update', type: :request do
  subject(:resource) { api.rel(:free_text_question).put(payload, params: {id: question.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:payload) { {points: 10.0, shuffle_answers: true} }

  let!(:question) { create(:free_text_question) }

  let(:item_update_request) do
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 11.0)
    ).to_return Stub.json({max_points: 11.0})
  end

  before do
    Stub.service(
      :course,
      items_url: 'http://course.xikolo.tld/items',
      item_url: 'http://course.xikolo.tld/items/{id}'
    )
    Stub.request(
      :course, :get, '/items',
      query: {content_id: question.quiz_id}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918', max_points: 10.0},
    ])
    item_update_request
  end

  it { is_expected.to respond_with :no_content }

  context 'when setting the question points' do
    let(:payload) { {points: new_points} }

    context 'with the old value' do
      let(:new_points) { 10.0 }

      it 'does not update the item\'s max_points' do
        resource
        expect(item_update_request).not_to have_been_requested
      end
    end

    context 'with a new value' do
      let(:new_points) { 11.0 }

      it 'updates the item\'s max_points' do
        resource
        expect(item_update_request).to have_been_requested
      end
    end
  end
end
