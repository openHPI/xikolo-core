# frozen_string_literal: true

require 'spec_helper'

describe SectionsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:section) { create(:section) }
  let(:default_params) { {format: 'json'} }

  before { section }

  describe "GET 'index'" do
    let(:action) { -> { get :index, params: } }

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
      expect(json[0]).to eq SectionDecorator.new(section).as_json(api_version: 1).stringify_keys
    end

    it 'returns a list with filter' do
      create(:section)
      get :index, params: {course_id: section.course_id}
      expect(json).to have(1).item
    end

    context 'with published filter' do
      it 'filters out unpublished sections' do
        create(:section, published: false)
        get :index, params: {published: true}
        expect(json).to have(1).item
      end
    end

    context 'with UUID' do
      let!(:sections) { create_list(:section, 10) }
      let(:params) { {id: sections[2].id} }

      before { action.call }

      it 'returns the correct section for UUID' do
        expect(json.map { it['id'] }).to contain_exactly(sections[2].id)
      end
    end

    context 'alternative sections' do
      it 'returns a filtered list without alternative_sections' do
        create(:section, alternative_state: 'child')
        get :index
        expect(json).to have(1).item
      end

      it 'returns a complete list with alternative_section filter' do
        create(:section, alternative_state: 'parent')
        get :index
        expect(json).to have(2).item
      end

      context 'with parent_id' do
        it 'returns a list of alternative_sections for that section' do
          create_list(:section, 4, alternative_state: 'child', parent_id: section.id)
          get :index, params: {parent_id: section.id}
          expect(json).to have(4).items
        end
      end

      context 'explicitly include_alternatives' do
        it 'returns all sections' do
          create_list(:section, 4, alternative_state: 'child', parent_id: section.id)
          get :index, params: {include_alternatives: true}
          expect(json).to have(5).items
        end
      end
    end
  end

  describe 'GET \'show\'' do
    let(:action) { -> { get :show, params: {id: section.id} } }

    before { action.call }

    context 'response' do
      subject { response }

      it 'responds with 200 OK' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'json' do
      subject { json }

      it 'responds with sections' do
        expect(json).to eq(SectionDecorator.new(section).as_json(api_version: 1).stringify_keys)
      end
    end
  end

  describe 'POST \'create\'' do
    let(:course) { create(:course) }
    let(:params) { attributes_for(:section, course_id: course.id) }

    it 'returns http success' do
      post(:create, params:)
      expect(response).to have_http_status :created
    end

    it 'creates a section on create' do
      expect { post(:create, params:) }.to change(Section, :count).from(1).to(2)
    end

    it 'answers with section' do
      post(:create, params:)
      expect(json['title']).to eq attributes_for(:section)[:title]
    end

    context 'with parent_id' do
      subject { action }

      let(:parent_params) { params.merge(parent_id: section.id) }
      let(:action) { -> { post :create, params: parent_params } }

      it 'changes state' do
        expect { action.call }.to change { section.reload.alternative_state }.from('none').to('parent')
      end
    end

    context 'with optional_section' do
      it 'rejects nil as value' do
        post :create, params: params.merge(optional_section: nil)
        expect(response).to have_http_status :unprocessable_content
      end
    end
  end

  describe 'PATCH \'update\'' do
    subject { action }

    let(:action) { -> { patch :update, params: params.merge(id: section.id) } }

    let(:course) { create(:course) }
    let(:section) { create(:section, course:) }

    let(:params) { {title: 'New Title'} }

    it 'changes the title' do
      expect { action.call }.to change { section.reload.title }.from(section.title).to('New Title')
    end

    context 'position update' do
      let(:sections) do
        (1..7).each_with_object([nil]) do |position, sections|
          sections << create(:section, course:, position:)
        end
      end

      context 'move to top' do
        let(:section) { sections[3] }
        let(:params) { {position: 1} }

        it 'moves the section to the top' do
          expect { action.call }.to change { sections[1].reload.position }.from(1).to(2)
            .and change { sections[2].reload.position }.from(2).to(3)
            .and change { sections[3].reload.position }.from(3).to(1)
        end
      end

      context 'move up' do
        let(:section) { sections[5] }
        let(:params) { {position: 3} }

        it 'moves the section up' do
          expect { action.call }.to change { sections[3].reload.position }.from(3).to(4)
            .and change { sections[4].reload.position }.from(4).to(5)
            .and change { sections[5].reload.position }.from(5).to(3)
        end
      end

      context 'move down' do
        let(:section) { sections[2] }
        let(:params) { {position: 4} }

        it 'moves the section to down' do
          expect { action.call }.to change { sections[2].reload.position }.from(2).to(4)
            .and change { sections[3].reload.position }.from(3).to(2)
            .and change { sections[4].reload.position }.from(4).to(3)
        end
      end

      context 'move to bottom' do
        let(:section) { sections[3] }
        let(:params) { {position: 7} }

        it 'moves the section to the bottom' do
          expect { action.call }.to change { sections[3].reload.position }.from(3).to(7)
            .and change { sections[4].reload.position }.from(4).to(3)
            .and change { sections[5].reload.position }.from(5).to(4)
            .and change { sections[6].reload.position }.from(6).to(5)
            .and change { sections[7].reload.position }.from(7).to(6)
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    subject { action }

    let(:action) { -> { delete :destroy, params: {id: section.id} } }
    let(:get_action) { -> { get :show, params: {id: section.id} } }
    let(:list_action) { -> { get :index, params: {course_id: section.course_id} } }

    it 'deletes the section' do
      expect { action.call }.to change { list_action.call; JSON[response.body].size }.from(1).to(0)
        .and change(Section, :count).from(1).to(0)
    end

    context 'after execution' do
      before { action.call; get_action.call }

      context 'response' do
        subject { response }

        it 'responds with 404 Not Found' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'with items' do
      before do
        create(:item, section:)
      end

      it 'does not change the section count' do
        expect { action }.not_to change(Section, :count)
      end

      it 'also does not change the amount of shown sections' do
        expect { action }.not_to change { list_action.call; JSON[response.body].size }
      end

      it 'returns http forbidden' do
        action.call
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with forks' do
      let(:course) { create(:course, :with_content_tree) }
      let(:section) { create(:section, course:) }

      before do
        create(:fork, section:, course:)
      end

      it 'also does not change the amount of shown sections' do
        expect { action }.not_to change(Section, :count)
        expect { action }.not_to change { list_action.call; JSON[response.body].size }
      end

      it 'returns http forbidden' do
        action.call
        expect(response).to have_http_status :forbidden
      end
    end

    context 'parent with children' do
      let(:section) { create(:section, :parent) }

      before do
        create_list(:section, 5, :child, parent: section)

        another_section = create(:section, :parent)
        create_list(:section, 3, :child, parent: another_section)
      end

      it 'removes the section and its child sections' do
        expect { action.call }.to change { list_action.call; JSON[response.body].size }.from(1).to(0)
          .and change(Section, :count).from(10).to(4)
      end
    end
  end
end
