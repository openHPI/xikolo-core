# frozen_string_literal: true

require 'spec_helper'

describe ClassifiersController, type: :controller do
  let(:classifier) { create(:classifier) }
  let(:json) { JSON.parse response.body }

  describe "GET 'index'" do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      classifier
      get :index
      expect(json).to have(1).item
    end

    it 'can filter by title' do
      matching = create(:classifier, title: 'Database Track')
      create(:classifier, title: 'Operating Systems Track')

      get :index, params: {q: 'base'}

      expect(json).to have(1).item
      expect(json.first['id']).to eq matching.id
    end

    it 'can filter by one cluster identifier' do
      track = create(:cluster, id: 'track')
      level = create(:cluster, id: 'level')
      create(:classifier, title: 'One', cluster: track)
      create(:classifier, title: 'Two', cluster: level)

      get :index, params: {cluster: 'track'}

      expect(json).to contain_exactly(hash_including('title' => 'One'))
    end

    it 'can filter by multiple cluster identifiers' do
      track = create(:cluster, id: 'track')
      level = create(:cluster, id: 'level')
      category = create(:cluster, id: 'category')
      create(:classifier, title: 'One', cluster: track)
      create(:classifier, title: 'Two', cluster: level)
      create(:classifier, title: 'Three', cluster: category)

      get :index, params: {cluster: 'track,level'}

      expect(json).to contain_exactly(hash_including('title' => 'One'), hash_including('title' => 'Two'))
    end

    it 'answers with classifier resources' do
      classifier
      get :index
      expect(json).to contain_exactly(hash_including(
        'id' => classifier.id,
        'title' => classifier.title,
        'cluster' => classifier.cluster_id,
        'courses' => [],
        'url' => "/classifiers/#{classifier.id}"
      ))
    end
  end

  describe "GET 'show'" do
    it 'returns HTTP success' do
      get :show, params: {id: classifier.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with a classifier resource' do
      get :show, params: {id: classifier.id}
      expect(json).to match hash_including(
        'id' => classifier.id,
        'title' => classifier.title,
        'cluster' => classifier.cluster_id,
        'courses' => [],
        'url' => "/classifiers/#{classifier.id}"
      )
    end
  end
end
