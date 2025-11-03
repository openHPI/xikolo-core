# frozen_string_literal: true

require 'spec_helper'

describe VotesController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:vote) { create(:'pinboard_service/vote') }
  let(:question) { create(:'pinboard_service/question') }
  let(:unvoted_uncommented_question) { create(:'pinboard_service/unvoted_uncommented_question') }

  # before { question }
  before { vote; unvoted_uncommented_question }

  describe "GET 'index'" do
    it 'responds with 200 Ok' do
      get :index
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      get :index
      expect(json.size).to eq(1)
    end

    it 'answers with vote resources' do
      get :index
      expect(json[0]).to eq(VoteDecorator.new(vote).as_json.stringify_keys)
    end
  end

  describe "GET 'show'" do
    it 'responds with 200 Ok' do
      get :show, params: {id: vote.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with a vote resource' do
      get :index, params: {id: vote.id}
      expect(json[0]).to eq(VoteDecorator.new(vote).as_json.stringify_keys)
    end
  end

  describe "POST 'create'" do
    it 'responds with 201 Created' do
      atts = attributes_for(:'pinboard_service/vote')
      atts[:votable_id] = unvoted_uncommented_question.id
      post :create, params: atts
      expect(response).to have_http_status :created
    end

    it 'creates a vote on create' do
      expect do
        atts = attributes_for(:'pinboard_service/vote')
        atts[:votable_id] = unvoted_uncommented_question.id
        post :create, params: atts
      end.to change(Vote, :count).by(1)
    end

    it 'answers with vote' do
      atts = attributes_for(:'pinboard_service/vote')
      atts[:votable_id] = unvoted_uncommented_question.id
      post :create, params: atts

      expect(json['value']).not_to be_nil
      expect(json['value']).to eq(attributes_for(:'pinboard_service/vote')[:value])
    end

    it 'does not create a vote twice' do
      expect do
        atts = attributes_for(:'pinboard_service/vote',
          votable_id: vote.votable_id,
          user_id: vote.user_id)
        post :create, params: atts
      end.not_to change(Vote, :count)
    end

    it 'answers with an error if a vote is created twice' do
      # atts = FactoryBot.attributes_for(:vote, votable_id: vote.votable_id) # TODO WHY?
      atts = vote.attributes.symbolize_keys
      post :create, params: atts
      expect(json['errors']).not_to be_nil
    end
  end

  describe "PUT 'update'" do
    it 'updates a vote' do
      put :update, params: {id: vote.id, value: '-1'}
      expect(response).to have_http_status :no_content
      get :show, params: {id: vote.id}
      expect(json['value']).to eq(-1)
    end
  end

  describe "DELETE 'destroy'" do
    it 'deletes a vote' do
      expect do
        delete :destroy, params: {id: vote.id}
      end.to change(Vote, :count).by(-1)
    end
  end
end
