# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::TagsController, type: :controller do
  routes { PinboardService::Engine.routes }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:tag) { create(:'pinboard_service/sql_tag') }
  let(:implicit_tag) { create(:'pinboard_service/section_tag') }
  let(:question) { create(:'pinboard_service/question') }
  let(:question_with_tags) { create(:'pinboard_service/question_with_tags') }
  let(:question_with_unrendered_tags) { create(:'pinboard_service/question_with_unrendered_tags') }

  before { tag; question }

  describe 'GET "index"' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status :ok
    end

    # index should work with course_id and question_id params

    describe 'with question id' do
      it 'returns a list' do
        get :index, params: {question_id: question_with_tags.id}
        expect(json.size).to eq(2)
      end

      it 'answers with tag resources' do
        get :index, params: {question_id: question_with_tags.id}
        expect(json).to include PinboardService::ExplicitTagDecorator.new(tag).as_json.stringify_keys
      end
    end

    describe 'with tag name' do
      it 'returns tag with name' do
        get :index, params: {name: tag.name, course_id: tag.course_id}
        expect(json[0]['name']).to eq tag.name
      end

      it 'answers with tag resource' do
        get :index, params: {name: tag.name, course_id: tag.course_id}
        expect(json).to include PinboardService::ExplicitTagDecorator.new(tag).as_json.stringify_keys
      end

      context 'uniqueness / case-insensitive' do
        subject(:get_tag) do
          get :index, params: attributes_for(:'pinboard_service/definition_tag').merge(name: 'definition')
        end

        before { create(:'pinboard_service/definition_tag') }

        it 'respects uniqueness when creating tag with same lower case name in same context' do
          expect { get_tag }.not_to change(PinboardService::Tag, :count)
        end

        it 'returns the existing upper case tag when requesting lower case' do
          get_tag
          expect(json[0]['name']).to eq 'Definition'
        end
      end

      context 'with non-existing tag' do
        subject(:get_tag) { get :index, params: attrs }

        let(:attrs) { attributes_for(:'pinboard_service/sql_tag').merge(name: 'non-existing', type: 'ExplicitTag') }

        it 'creates and returns the non-existing tag' do
          expect { get_tag }.to change(PinboardService::Tag, :count).by(1)
          expect(json[0]['name']).to eq 'non-existing'
        end
      end
    end

    describe 'with implicit tag id' do
      it 'returns tag with name' do
        get :index, params: {name: implicit_tag.name, referenced_resource: implicit_tag.referenced_resource, course_id: tag.course_id}
        expect(json[0]['name']).to eq implicit_tag.name
      end

      it 'answers with tag resource' do
        get :index, params: {type: 'ImplicitTag', name: implicit_tag.name, referenced_resource: implicit_tag.referenced_resource, course_id: tag.course_id}
        expect(json).to include PinboardService::ImplicitTagDecorator.new(implicit_tag).as_json.stringify_keys
      end
    end
  end

  describe "GET 'show'" do
    it 'returns http success' do
      get :show, params: {id: tag.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with a tag resource' do
      get :show, params: {id: tag.id}
      expect(json).to eq PinboardService::ExplicitTagDecorator.new(tag).as_json.stringify_keys
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      post :create, params: attributes_for(:'pinboard_service/definition_tag')
      expect(response).to have_http_status :created
    end

    it 'creates a tag on create' do
      expect do
        post :create, params: attributes_for(:'pinboard_service/definition_tag')
      end.to change(PinboardService::Tag, :count).by(1)
    end

    it 'answers with a tag' do
      post :create, params: attributes_for(:'pinboard_service/definition_tag')

      expect(json['name']).not_to be_nil
      expect(json['name']).to eq attributes_for(:'pinboard_service/definition_tag')[:name]
    end
  end
end
