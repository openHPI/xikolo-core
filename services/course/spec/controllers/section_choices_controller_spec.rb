# frozen_string_literal: true

require 'spec_helper'

describe SectionChoicesController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:data) { json.to_struct }
  let(:default_params) { {format: 'json'} }
  let(:section_choice) { create(:section_choice) }

  before { section_choice }

  describe "GET 'index'" do
    let(:action) { -> { get :index } }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      get :index
      expect(json).to have(1).item
    end

    it 'answers with section resources' do
      get :index
      expect(json[0]).to eq SectionChoiceDecorator.new(section_choice).as_json(api_version: 1).stringify_keys
    end

    context 'with filter' do
      let(:user_id) { SecureRandom.uuid }
      let(:section) { create(:section) }

      before do
        create(:section_choice, user_id:)
        create(:section_choice, user_id:, section:)
        create(:section_choice, user_id: SecureRandom.uuid, section:)
        create(:section_choice, user_id: SecureRandom.uuid, section:)
      end

      it 'returns a list with user_id filter' do
        get :index, params: {user_id:}
        expect(json).to have(2).item
      end

      it 'returns a list with section_id filter' do
        get :index, params: {section_id: section.id}
        expect(json).to have(3).items
      end

      it 'returns a list with user_id and section_id filter' do
        get :index, params: {user_id:, section_id: section.id}
        expect(json).to have(1).item
      end
    end
  end

  describe "POST 'create'" do
    let(:chosen_section_id) { SecureRandom.uuid }
    let(:new_user_id) { SecureRandom.uuid }
    let(:section) { create(:section, :parent) }
    let(:params) { {section_id: section.id, user_id: new_user_id, chosen_section_id:} }

    it 'returns http success' do
      post(:create, params:)
      expect(response).to have_http_status :created
    end

    it 'creates a section_choice on create' do
      post(:create, params:)
      expect(SectionChoice.count).to eq(2)
    end

    it 'answers with section_choice' do
      post(:create, params:)
      choice = SectionChoice.find_by(user_id: new_user_id, section_id: section.id)
      expect(choice.choice_ids).to eq [chosen_section_id]
    end
  end
end
