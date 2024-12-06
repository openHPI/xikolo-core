# frozen_string_literal: true

require 'spec_helper'

describe ItemsController, type: :controller do
  let(:item) { create(:item) }
  let(:json) { JSON.parse response.body }

  describe '#index' do
    let(:params) { {} }
    let(:action) { get :index, params: }

    it 'responds with 200 Ok' do
      action
      expect(response).to have_http_status :ok
    end

    context 'with existing item' do
      before { item }

      describe 'response' do
        before { action }

        it 'responds with 200 Ok' do
          expect(response).to have_http_status :ok
        end

        it 'contains a Link header to the first page' do
          expect(response.headers['Link'].to_s).to include 'rel="first"'
        end

        describe 'json' do
          it 'contains the correct item resource' do
            expect(json).to contain_exactly(ItemDecorator.new(item, context: {collection: true}).as_json(api_version: 1))
          end
        end
      end
    end

    describe '^filter' do
      context 'with section_id param set' do
        let(:section) { create(:section) }
        let(:item) { create(:item, section:) }
        let(:params) { {section_id: section.id} }

        before { item; action }

        describe 'json' do
          it 'has one item' do
            expect(json).to have(1).item
          end

          it 'contains the correct item resource' do
            expect(json.first['id']).to eq item.id
          end
        end
      end

      context 'with section_id param set as array' do
        let(:section) { create(:section) }
        let(:item) { create(:item, section:) }
        let(:params) { {section_id: ['6551282f-b22f-43dd-855c-2860f560f54e', section.id]} }

        before { item; action }

        describe 'json' do
          it 'has one item' do
            expect(json).to have(1).item
          end

          it 'contains the correct item resource' do
            expect(json.first['id']).to eq item.id
          end
        end
      end

      context 'with item from all sections only' do
        let(:section) { create(:section, published: true) }
        let(:item) { create(:item, section:, published: true) }

        let(:params) { {available: false, course_id: section.course_id} }

        before { item; action }

        describe 'json' do
          it 'has one item' do
            expect(json).to have(1).item
          end

          it 'contains the correct item resource' do
            expect(json.first['id']).to eq item.id
          end
        end
      end

      context 'with item from available sections only' do
        let(:section) { create(:section, published: true, start_date: 10.hours.ago.iso8601) }
        let(:item) { create(:item, section:, published: true, start_date: 10.hours.ago.iso8601) }
        let(:params) { {available: true, course_id: section.course_id} }

        before { item; action }

        describe 'json' do
          it 'has one item' do
            expect(json).to have(1).item
          end

          it 'contains the correct item resource' do
            expect(json.first['id']).to eq item.id
          end
        end
      end

      context 'with item from unavailable sections only' do
        let(:section) { create(:section, published: true) }
        let(:item) { create(:item, section:, published: true) }
        let(:params) { {available: true, course_id: section.course_id} }

        before { item; action }

        describe 'json' do
          it 'has no items' do
            expect(json).to have(0).items
          end
        end
      end

      context 'with published item' do
        let!(:item) { create(:item, published: true) }
        let(:params) { {published: true} }

        # And an unpublished item for good measure
        before { create(:item, published: false) }

        describe 'json' do
          it 'has one item' do
            action
            expect(json).to have(1).item
          end

          it 'contains the correct item resource' do
            action
            expect(json.first['id']).to eq item.id
          end
        end
      end

      context 'with featured item' do
        context 'with published item' do
          let!(:featured_item) { create(:item, featured: true, public_description: 'Lorem ipsum ...') }
          let(:params) { {featured: true} }

          before do
            create(:item)
            action
          end

          describe 'json' do
            it 'has one item' do
              expect(json).to have(1).item
            end

            it 'contains the correct item resource' do
              expect(json.first['id']).to eq featured_item.id
            end
          end
        end
      end

      context 'with open_mode' do
        let(:start_date) { 10.days.ago }
        let(:course) { create(:course, start_date:) }
        let(:section) { create(:section, course:, start_date: nil, end_date: nil) }
        let!(:open_item) { create(:item, section:, open_mode: true, start_date: nil, end_date: nil) }

        # And two closed items for good measure
        before do
          create_list(:item, 2, section:, open_mode: false, start_date: nil, end_date: nil)
          action
        end

        context 'with published item' do
          let(:params) { {course_id: course.id, open_mode: true} }

          describe 'json' do
            it 'has one item' do
              expect(json).to have(1).item
            end

            it 'contains the correct item resource' do
              expect(json.first['id']).to eq open_item.id
            end
          end
        end

        context 'without course_id' do
          let(:params) { {open_mode: true} }

          describe 'json' do
            it 'is empty' do
              expect(json).to have(0).items
            end
          end
        end

        context 'with future course' do
          let(:params) { {course_id: course.id, open_mode: true} }
          let(:start_date) { 10.days.from_now }

          describe 'json' do
            it 'is empty' do
              expect(json).to have(0).items
            end
          end
        end
      end

      context 'without unpublished item' do
        let(:item) { create(:item, published: false) }
        let(:params) { {published: true} }

        before { item; action }

        describe 'json' do
          it 'has no items' do
            expect(json).to have(0).items
          end
        end
      end

      context 'with available' do
        let(:course) { create(:course) }

        let(:available_section_1) { create(:section, course_id: course.id, published: true, start_date: DateTime.now - 1000, position: 1) }
        let(:available_section_2) { create(:section, course_id: course.id, published: true, start_date: DateTime.now - 1000, position: 2) }
        let(:available_section_3) { create(:section, course_id: course.id, published: true, start_date: DateTime.now - 1000, position: 3) }

        let(:unavailable_section) { create(:section, course_id: course.id, published: true, end_date: DateTime.now + 1000, position: 4) }

        let(:available_item_in_unavailable_section) { create(:item, section_id: unavailable_section.id, published: true, position: 1) }

        let(:unavailable_item_1_in_available_section_1) { create(:item, section_id: available_section_1.id, published: false, position: 1) }
        let(:available_item_2_in_available_section_1)   { create(:item, section_id: available_section_1.id, published: true, position: 2) }
        let(:available_item_3_in_available_section_1)   { create(:item, section_id: available_section_1.id, published: true, position: 3) }
        let(:available_item_4_in_available_section_1)   { create(:item, section_id: available_section_1.id, published: true, position: 4) }

        let(:available_item_1_in_available_section_2)   { create(:item, section_id: available_section_2.id, published: true, position: 1) }
        let(:available_item_2_in_available_section_2)   { create(:item, section_id: available_section_2.id, published: true, position: 2) }
        let(:available_item_3_in_available_section_2)   { create(:item, section_id: available_section_2.id, published: true, position: 3) }

        let(:available_item_1_in_available_section_3)   { create(:item, section_id: available_section_3.id, published: true, position: 1) }
        let(:available_item_2_in_available_section_3)   { create(:item, section_id: available_section_3.id, published: true, position: 2) }
        let(:available_item_3_in_available_section_3)   { create(:item, section_id: available_section_3.id, published: true, position: 3) }

        let(:params) { {course_id: course.id, available: true} }

        before do
          # create items in shuffled order to test ordering
          available_item_in_unavailable_section

          available_item_4_in_available_section_1

          available_item_3_in_available_section_3
          available_item_3_in_available_section_2
          available_item_3_in_available_section_1

          available_item_2_in_available_section_3
          available_item_2_in_available_section_2
          available_item_2_in_available_section_1

          available_item_1_in_available_section_3
          available_item_1_in_available_section_2

          unavailable_item_1_in_available_section_1
        end

        it 'responds with 200 Ok' do
          action
          expect(response).to have_http_status :ok
        end

        describe 'response' do
          before { action }

          it 'has 9 items' do
            expect(json).to have(9).items
          end

          it 'only has available items in available sections with course order' do
            expect(json[0]['id']).to eq available_item_2_in_available_section_1.id
            expect(json[1]['id']).to eq available_item_3_in_available_section_1.id
            expect(json[2]['id']).to eq available_item_4_in_available_section_1.id
            expect(json[3]['id']).to eq available_item_1_in_available_section_2.id
            expect(json[4]['id']).to eq available_item_2_in_available_section_2.id
            expect(json[5]['id']).to eq available_item_3_in_available_section_2.id
            expect(json[6]['id']).to eq available_item_1_in_available_section_3.id
            expect(json[7]['id']).to eq available_item_2_in_available_section_3.id
            expect(json[8]['id']).to eq available_item_3_in_available_section_3.id
          end
        end
      end

      context 'with was_available' do
        let(:course) { create(:course) }

        let(:unavailable_section) { create(:section, course_id: course.id, published: true, start_date: 1.week.from_now) }
        let(:available_section)   { create(:section, course_id: course.id, published: true, start_date: 1.week.ago) }

        let(:available_item_in_unavailable_section) { create(:item, section_id: unavailable_section.id, published: true) }
        let(:unavailable_item_in_available_section) do
          create(:item, section_id: available_section.id, published: true, start_date: DateTime.now + 1000, position: 1)
        end
        let(:available_item_in_available_section_2)   { create(:item, section_id: available_section.id, published: true, position: 3) }
        let(:available_item_in_available_section_3)   { create(:item, section_id: available_section.id, published: true, position: 4) }
        let(:available_item_in_available_section_1)   { create(:item, section_id: available_section.id, published: true, position: 2) }

        let(:params) { {course_id: course.id, was_available: true} }

        before { available_item_in_unavailable_section; unavailable_item_in_available_section; available_item_in_available_section_1; available_item_in_available_section_2; available_item_in_available_section_3 }

        it 'responds with 200 Ok' do
          action
          expect(response).to have_http_status :ok
        end

        describe 'response' do
          before { action }

          it 'has 3 items' do
            expect(json).to have(3).items
          end

          it 'only has available item in available section' do
            expect(json.first['id']).to eq available_item_in_available_section_1.id
          end
        end
      end

      context 'with course_id param set' do
        let(:course)         { create(:course) }
        let(:another_course) { create(:course) }
        let(:sections_for_course) do
          create_list(:section, 4, course_id: course.id)
        end
        let(:sections_for_another_course) do
          create_list(:section, 4, course_id: another_course.id)
        end
        let(:items_for_course) do
          item_sections = sections_for_course.collect do |section|
            create_list(:item, 5, section_id: section.id)
          end
          item_sections.flatten
        end
        let(:items_for_another_course) do
          item_sections = sections_for_another_course.collect do |section|
            create_list(:item, 5, section_id: section.id)
          end
          item_sections.flatten
        end

        let(:params) { {course_id: course.id} }

        before { items_for_course; items_for_another_course }

        it 'responds successfully' do
          action
          expect(response).to be_successful
        end

        describe 'response' do
          before { action }

          it 'has 20 items' do
            expect(json).to have(20).items
          end

          it 'has correct items only' do
            expect(json.pluck('id')).to match_array items_for_course.pluck(:id)
          end
        end

        context 'caching' do
          before { action }

          it 'responds with 200 Ok' do
            expect(response).to have_http_status :ok
          end
        end
      end

      context 'with content type filter set' do
        let(:quiz_items)  { create_list(:item, 3, :quiz) }
        let(:video_items) { create_list(:item, 4, content_type: 'video') }
        let(:params) { {content_type: 'quiz'} }

        before { quiz_items; video_items; action }

        it 'has only quiz items' do
          expect(json).to have(quiz_items.count).items
        end

        it 'only contains items with correct content type' do
          response_values = json.collect do |entry|
            entry.with_indifferent_access[:content_type]
          end
          expect(response_values.uniq).to eq [params[:content_type]]
        end
      end

      context 'with exercise type filter set' do
        let!(:main_items) { create_list(:item, 2, content_type: 'quiz', exercise_type: 'main') }
        let(:params) { {exercise_type: 'main'} }

        # Plus a few bonus and video items that won't be included
        before do
          create_list(:item, 3, content_type: 'quiz', exercise_type: 'bonus')
          create(:item, content_type: 'video', exercise_type: nil)
        end

        it 'has only main items' do
          action
          expect(json).to have(main_items.count).items
        end

        it 'only contains items with correct exercise type' do
          action
          expect(json.pluck('id')).to match_array main_items.pluck(:id)
        end
      end

      context 'with multiple exercise type filter set as array' do
        let!(:main_items)  { create_list(:item, 2, content_type: 'quiz', exercise_type: 'main') }
        let!(:bonus_items) { create_list(:item, 3, content_type: 'quiz', exercise_type: 'bonus') }
        let(:params) { {exercise_type: %w[main bonus]} }

        # And another video item that won't be included
        before { create(:item, content_type: 'video', exercise_type: nil) }

        it 'has only main items' do
          action
          expect(json).to have(main_items.count + bonus_items.count).items
        end

        it 'only contains items with correct exercise type' do
          action
          expect(json.pluck('id')).to match_array((main_items + bonus_items).pluck(:id))
        end
      end

      context 'with multiple exercise type filter set as comma-separated list' do
        let!(:main_items)  { create_list(:item, 2, content_type: 'quiz', exercise_type: 'main') }
        let!(:bonus_items) { create_list(:item, 3, content_type: 'quiz', exercise_type: 'bonus') }
        let(:params) { {exercise_type: 'main,bonus'} }

        # And another video item that won't be included
        before { create(:item, content_type: 'video', exercise_type: nil) }

        it 'has only main items' do
          action
          expect(json).to have(main_items.count + bonus_items.count).items
        end

        it 'only contains items with correct exercise type' do
          action
          expect(json.pluck('id')).to match_array((main_items + bonus_items).pluck(:id))
        end
      end

      context 'with multiple exercise type filter set' do
        let!(:main_items)  { create_list(:item, 2, content_type: 'quiz', exercise_type: 'main') }
        let!(:bonus_items) { create_list(:item, 3, content_type: 'quiz', exercise_type: 'bonus') }
        let(:params) { {exercise_type: {'0' => 'main', '1' => 'bonus'}} }

        # And another video item that won't be included
        before { create(:item, content_type: 'video', exercise_type: nil) }

        it 'has only main items' do
          action
          expect(json).to have(main_items.count + bonus_items.count).items
        end

        it 'only contains items with correct exercise type' do
          action
          expect(json.pluck('id')).to match_array((main_items + bonus_items).pluck(:id))
        end
      end
    end

    context 'with UUID' do
      before { action.call }

      let(:video_items) { create_list(:item, 4, content_type: 'video') }
      let(:params) { {id: video_items[2].id} }
      let(:action) { -> { get :index, params: } }

      it 'returns the correct section for UUID' do
        expect(json.pluck('id')).to contain_exactly(video_items[2].id)
      end
    end

    context 'with new_for' do
      let(:user_id) { generate(:user_id) }
      let(:params) { {new_for: user_id} }
      let!(:items) { create_list(:item, 4) }

      before { item }

      context 'without visits' do
        it 'has 5 items' do
          action
          expect(json).to have(5).items
        end
      end

      context 'with visit' do
        before { create(:visit, user_id:, item:) }

        it 'has 4 items' do
          action
          expect(json).to have(4).items
        end

        it 'contains the unvisited items' do
          action
          expect(json.pluck('id')).to match_array items.pluck(:id)
        end
      end
    end
  end

  describe '#show' do
    let(:action) { -> { get :show, params: {id: item.id} } }

    context 'response' do
      subject { response }

      before { action.call }

      it { is_expected.to have_http_status :ok }
    end

    context 'json' do
      subject { json }

      before { action.call }

      it { is_expected.to eq ItemDecorator.new(item).as_json(api_version: 1).stringify_keys }
    end

    context 'with user id' do
      let(:item) { create(:item, submission_deadline: Time.zone.now.midnight - 1.day) }
      let(:user_id) { SecureRandom.uuid }
      let(:forced_submission_date) { Time.zone.now.midnight }
      let(:enrollment) do
        create(:enrollment,
          user_id:,
          course: item.section.course,
          forced_submission_date:)
      end
      let(:action) { -> { get :show, params: {id: item.id, for_user: user_id} } }

      before { enrollment; action.call }

      it 'has the forced_submission_date as submission_deadline' do
        expect(Time.zone.parse(json['submission_deadline'])).to eq Time.zone.parse(forced_submission_date.to_s)
      end
    end
  end

  describe '#create' do
    let(:section) { create(:section) }
    let(:params) { attributes_for(:item).merge(section_id: section.id) }
    let(:action) { -> { post :create, params: } }

    it 'responses with a 200' do
      action.call
      expect(response).to have_http_status :created
    end

    it 'creates new item' do
      expect { action.call }.to change(Item, :count).from(0).to(1)
    end

    it 'is a proper list' do
      2.times { action.call }
      get :index
      expect(json).to have(2).item
      expect(json[0]['position']).to eq 1
      expect(json[1]['position']).to eq 2
    end

    context 'with invalid data' do
      let(:params) { {title: 'test'} }

      it 'responses with 422 on invalid data' do
        action.call
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context 'with not round float value' do
      subject { action.call; response }

      let(:params) { super().merge max_points: 2.13 }

      its(:status) { is_expected.to eq 422 }

      context 'json' do
        subject { action.call; json }

        it { is_expected.to eq 'errors' => {'max_points' => ['invalid_format']} }
      end
    end

    context 'with negative value' do
      subject { action.call; response }

      let(:params) { super().merge max_points: -2 }

      its(:status) { is_expected.to eq 422 }

      context 'json' do
        subject { action.call; json }

        it { is_expected.to eq 'errors' => {'max_points' => ['invalid_format']} }
      end
    end

    context 'with featured flag' do
      let(:params) { super().merge(featured: true, public_description: 'Lorem ipsum ...') }

      it 'responds with a 201' do
        action.call
        expect(response).to have_http_status :created
      end

      it 'creates a new item' do
        expect { action.call }.to change(Item, :count).from(0).to(1)
      end
    end

    context 'with required items' do
      subject(:item) { action.call; json }

      let(:req_items) { create_list(:item, 2) }
      let(:req_item_ids) { req_items.pluck(:id) }
      let(:params) { super().merge(required_item_ids: req_item_ids) }

      it 'contains a representation for the required items' do
        expect(item['required_item_ids']).to match(req_item_ids)
      end

      context '(containing a non-existent item)' do
        let(:missing_item_id) { SecureRandom.uuid }
        let(:req_item_ids) { super() << missing_item_id }

        it 'fails with missing item' do
          expect(item['errors']['required_item_ids']).to include("must identify an item (failed for: #{missing_item_id})")
        end
      end

      context '(containing nil - regression spec)' do
        let(:missing_item_id) { nil }
        let(:req_item_ids) { super() << missing_item_id }

        it 'fails with missing item' do
          expect(item['errors']['required_item_ids']).to include('must identify an item (failed for: empty item)')
        end
      end
    end
  end

  describe '#update' do
    subject { action }

    let(:action) { -> { patch :update, params: params.merge(id: item.id) } }

    let(:section) { create(:section) }
    let(:item) { create(:item, section:, position: 1) }

    context 'with not round float value' do
      subject { action.call; response }

      let(:params) { {max_points: 2.13} }

      its(:status) { is_expected.to eq 422 }

      context 'json' do
        subject { action.call; json }

        it { is_expected.to eq 'errors' => {'max_points' => ['invalid_format']} }
      end
    end

    context 'with negative value' do
      subject { action.call; response }

      let(:params) { {max_points: -2} }

      its(:status) { is_expected.to eq 422 }

      context 'json' do
        subject { action.call; json }

        it { is_expected.to eq 'errors' => {'max_points' => ['invalid_format']} }
      end
    end

    context 'position update' do
      let(:items) do
        (1..7).each_with_object([nil]) do |position, items|
          items << create(:item, section:, position:)
        end
      end

      context 'move to top' do
        let(:item) { items[3] }
        let(:params) { {position: 1} }

        it { expect { action.call }.to change { items[1].reload.position }.from(1).to(2) }
        it { expect { action.call }.to change { items[2].reload.position }.from(2).to(3) }
        it { expect { action.call }.to change { items[3].reload.position }.from(3).to(1) }
      end

      context 'move up' do
        let(:item) { items[5] }
        let(:params) { {position: 3} }

        it { expect { action.call }.to change { items[3].reload.position }.from(3).to(4) }
        it { expect { action.call }.to change { items[4].reload.position }.from(4).to(5) }
        it { expect { action.call }.to change { items[5].reload.position }.from(5).to(3) }
      end

      context 'move down' do
        let(:item) { items[2] }
        let(:params) { {position: 4} }

        it { expect { action.call }.to change { items[2].reload.position }.from(2).to(4) }
        it { expect { action.call }.to change { items[3].reload.position }.from(3).to(2) }
        it { expect { action.call }.to change { items[4].reload.position }.from(4).to(3) }
      end

      context 'move to bottom' do
        let(:item) { items[3] }
        let(:params) { {position: 7} }

        it { expect { action.call }.to change { items[3].reload.position }.from(3).to(7) }
        it { expect { action.call }.to change { items[4].reload.position }.from(4).to(3) }
        it { expect { action.call }.to change { items[5].reload.position }.from(5).to(4) }
        it { expect { action.call }.to change { items[6].reload.position }.from(6).to(5) }
        it { expect { action.call }.to change { items[7].reload.position }.from(7).to(6) }
      end
    end
  end

  describe 'with versioning', :versioning do
    let(:item) { create(:item, title: 'Introduction') }
    let(:update_title) { -> { put :update, params: {id: item.id, title: 'Welcome'} } }

    it 'returns one version at the beginning' do
      expect(item.versions.size).to eq 1
    end

    it 'returns two versions when modified' do
      update_title.call
      item.reload
      expect(item.versions.size).to eq 2
    end

    it 'answers with the previous version' do
      update_title.call
      item.reload
      expect(item.title).to eq 'Welcome'
      expect(item.paper_trail.previous_version.title).to eq 'Introduction'
    end

    context 'with given timestamp' do
      it 'show action should return version of item at this time' do
        Timecop.freeze do
          Timecop.travel(2008, 9, 1, 12, 0, 0)
          item

          Timecop.travel(2010, 9, 1, 12, 0, 0)
          update_title.call
        end

        item.reload
        expect(item.title).to eq 'Welcome'
        params = {id: item.id, version_at: DateTime.new(2009, 9, 1, 12, 0, 0).to_s}
        get(:show, params:)
        expect(json['title']).to eq 'Introduction'
      end
    end
  end

  describe '#current' do
    subject { action; response }

    let(:user_id) { generate(:user_id) }
    let(:enrollment) { create(:enrollment, user_id:, course:) }
    let(:course) { create(:course) }

    let(:section1_params) { {} }
    let(:section1) { create(:section, {course:, position: 1, start_date: 10.days.ago.iso8601}.merge(section1_params)) }
    let(:item11_params) { {} }
    let(:item11) { create(:item, {section: section1, position: 1}.merge(item11_params)) }
    let(:item12_params) { {} }
    let(:item12) { create(:item, {section: section1, position: 2}.merge(item12_params)) }

    let(:section2_params) { {} }
    let(:section2) { create(:section, {course:, position: 2, start_date: 10.days.ago.iso8601}.merge(section2_params)) }
    let(:item21_params) { {} }
    let(:item21) { create(:item, {section: section2, position: 1}.merge(item21_params)) }
    let(:item22_params) { {} }
    let(:item22) { create(:item, {section: section2, position: 2}.merge(item22_params)) }

    let(:action) { get :current, params: {course: course.id, user: user_id} }

    before { enrollment }

    shared_examples 'a visitable item' do |expected_item_name|
      its(:status) { is_expected.to eq 200 }

      context 'with a json response' do
        subject { action; json }

        its(['id']) { is_expected.to eq send(expected_item_name).id }
        its(['published']) { is_expected.to be true }

        # TODO: check effective start and end date -> item must be public
      end
    end

    shared_examples 'a non-existing item' do
      its(:status) { is_expected.to eq 404 }

      context 'json' do
        subject { action; json }

        it { is_expected.to eq('reason' => 'not_public_item') }
      end
    end

    context 'without any course items or progress items' do
      it_behaves_like 'a non-existing item'
    end

    context 'with only one section' do
      before { section1 }

      shared_context 'a redirection to the following section/items' do
        before { section2; item21; item22 }

        it_behaves_like 'a visitable item', :item21

        context 'with a visit for a later item' do
          before { create(:visit, user_id:, item: item22) }

          it_behaves_like 'a visitable item', :item22
        end
      end

      shared_context 'a non-existing section (inclusive child resources)' do
        it_behaves_like 'a non-existing item'

        context 'with a published item' do
          before { item11 }

          it_behaves_like 'a non-existing item'

          context 'with a progress item pointing on it' do
            before { create(:visit, user_id:, item: item11) }

            it_behaves_like 'a non-existing item'
            it_behaves_like 'a redirection to the following section/items'
          end
        end

        it_behaves_like 'a redirection to the following section/items'
      end

      context 'unpublished' do
        let(:section1_params) { {published: false} }

        it_behaves_like 'a non-existing section (inclusive child resources)'
      end

      context 'published but not started section' do
        let(:section1_params) { {published: true, start_date: DateTime.now + 10.minutes} }

        it_behaves_like 'a non-existing section (inclusive child resources)'
      end

      context 'published but ended section' do
        let(:section1_params) { {published: true, end_date: DateTime.now - 10.minutes} }

        it_behaves_like 'a non-existing section (inclusive child resources)'
      end

      context 'as a previewer' do
        let(:action) { get :current, params: {course: course.id, user: user_id, preview: 'true'} }

        before { section1; item11 }

        context 'with a visit for a later item' do
          before { section2; item21; item22; create(:visit, user_id:, item: item22) }

          it_behaves_like 'a visitable item', :item22
        end

        context 'without being enrolled in the course' do
          let(:enrollment) { nil }

          shared_examples 'the first item' do
            its(:status) { is_expected.to eq 200 }

            it 'redirects to the item' do
              action
              expect(json['id']).to eq item11.id
            end
          end

          it_behaves_like 'the first item'

          context 'unpublished' do
            let(:section1_params) { {published: false} }

            it_behaves_like 'the first item'
          end

          context 'published but not started section' do
            let(:section1_params) { {published: true, start_date: DateTime.now + 10.minutes} }

            it_behaves_like 'the first item'
          end

          context 'published but ended section' do
            let(:section1_params) { {published: true, end_date: DateTime.now - 10.minutes} }

            it_behaves_like 'the first item'
          end
        end
      end
    end

    context 'with forks (and branches)' do
      let(:course) { create(:course, :with_content_tree) }
      let(:item_branch1) { create(:item, section: section1, title: 'Item in Branch 1') }
      let(:item_branch2) { create(:item, section: section1, title: 'Item in Branch 2') }
      let(:fork) { create(:fork, section: section1, course:, title: 'Fork') }

      before do
        # Reload course structure record to recalculate tree indices.
        course.node.reload
      end

      context 'without any course items' do
        it_behaves_like 'a non-existing item'
      end

      context 'with only one section' do
        before do
          fork
          item_branch1.node.move_to_child_of(fork.branches[0].node)
          item_branch2.node.move_to_child_of(fork.branches[1].node)

          # Reload course structure record to recalculate tree indices.
          course.node.reload
        end

        shared_context 'a redirection to the following section/items' do
          before { section2; item21; item22 }

          it_behaves_like 'a visitable item', :item21

          context 'with a visit for a later item' do
            before { create(:visit, user_id:, item: item22) }

            it_behaves_like 'a visitable item', :item22
          end
        end

        shared_context 'a non-existing section (inclusive child resources)' do
          it_behaves_like 'a non-existing item'

          context 'with a published item' do
            before { item11 }

            it_behaves_like 'a non-existing item'

            context 'with a visit for the item' do
              before { create(:visit, user_id:, item: item11) }

              it_behaves_like 'a non-existing item'
              it_behaves_like 'a redirection to the following section/items'
            end
          end

          it_behaves_like 'a redirection to the following section/items'
        end

        context 'unpublished' do
          let(:section1_params) { {published: false} }

          it_behaves_like 'a non-existing section (inclusive child resources)'
        end

        context 'published but not started section' do
          let(:section1_params) { {published: true, start_date: DateTime.now + 10.minutes} }

          it_behaves_like 'a non-existing section (inclusive child resources)'
        end

        context 'published but ended section' do
          let(:section1_params) { {published: true, end_date: DateTime.now - 10.minutes} }

          it_behaves_like 'a non-existing section (inclusive child resources)'
        end
      end

      context "with the first (resume) item not belonging to the user's branch" do
        before do
          fork
          # Switch positions for the legacy implementation (creation order).
          item_branch2.node.move_to_child_of(fork.branches[1].node)
          item_branch1.node.move_to_child_of(fork.branches[0].node)

          # Switch positions for the items in the course tree.
          fork.branches[1].node.move_to_left_of(fork.branches[0].node)

          # Reload course structure record to recalculate tree indices.
          course.node.reload

          items = Structure::UserItemsSelector.new(course.node, user_id).items
          expect(items).to eq [item_branch1]
        end

        # The user is automatically assigned to a group (branch 1) when requesting the item.
        # It's not allowed to access the item from branch 2, so expect a redirect.
        it_behaves_like 'a visitable item', :item_branch1

        context 'with a visit for a later item in the same section' do
          before do
            create(:visit, user_id:, item: item12)

            items = Structure::UserItemsSelector.new(course.node, user_id).items
            expect(items).to eq [item_branch1, item12]
          end

          it_behaves_like 'a visitable item', :item12
        end

        context 'with a visit for a later item in another section' do
          before do
            section2
            create(:visit, user_id:, item: item22)

            # Reload course structure record to recalculate tree indices.
            course.node.reload

            items = Structure::UserItemsSelector.new(course.node, user_id).items
            expect(items).to eq [item_branch1, item22]
          end

          it_behaves_like 'a visitable item', :item22
        end

        context "with a visit for the item not belonging to the user's branch" do
          # This use case is a safe-guard, having a visit for such an item is
          # not a realistic use case. We want to make sure this item is ignored.
          before do
            create(:visit, user_id:, item: item_branch2)
          end

          # The user is automatically assigned to a group (branch 1) when requesting the item.
          # It's not allowed to access the item from branch 2, so expect a redirect.
          it_behaves_like 'a visitable item', :item_branch1
        end
      end

      context 'as anonymous user' do
        let(:user_id) { 'anonymous' }
        let(:enrollment) { nil }

        context 'with the first (resume) item belonging to a branch' do
          before do
            fork
            # Switch positions for the legacy implementation (creation order).
            item_branch2.node.move_to_child_of(fork.branches[1].node)
            item_branch1.node.move_to_child_of(fork.branches[0].node)

            # Reload course structure record to recalculate tree indices.
            course.node.reload

            items = Structure::UserItemsSelector.new(course.node, user_id).items
            expect(items).to eq []
          end

          # Anonymous users are not assigned to a group. It's not allowed to
          # access the items from branches.
          it_behaves_like 'a non-existing item'

          context 'with a regular item not being available in open mode' do
            before do
              item12

              items = Structure::UserItemsSelector.new(course.node, user_id).items
              expect(items).to eq [item12]
            end

            # Additional scopes are applied for anonymous users, only making
            # open mode items accessible.
            it_behaves_like 'a non-existing item'
          end

          context 'with a regular item being available in open mode' do
            let(:item12_params) { super().merge(open_mode: true) }

            before do
              item12

              items = Structure::UserItemsSelector.new(course.node, user_id).items
              expect(items).to eq [item12]
            end

            # Additional scopes are applied for anonymous users,
            # only making open mode items accessible.
            it_behaves_like 'a visitable item', :item12
          end
        end
      end

      context 'as not enrolled logged-in user' do
        let(:enrollment) { nil }

        context 'with the first (resume) item belonging to a branch' do
          before do
            fork
            # Switch positions for the legacy implementation (creation order).
            item_branch2.node.move_to_child_of(fork.branches[1].node)
            item_branch1.node.move_to_child_of(fork.branches[0].node)

            # Reload course structure record to recalculate tree indices.
            course.node.reload

            items = Structure::UserItemsSelector.new(course.node, user_id).items
            expect(items).to eq [item_branch1]
          end

          # Anonymous users are not assigned to a group. It's not allowed to
          # access the items from branches.
          it_behaves_like 'a non-existing item'

          context 'with a regular item not being available in open mode' do
            before do
              item12

              items = Structure::UserItemsSelector.new(course.node, user_id).items
              expect(items).to eq [item_branch1, item12]
            end

            # Additional scopes are applied for anonymous users, only making
            # open mode items accessible.
            it_behaves_like 'a non-existing item'
          end

          context 'with a regular item being available in open mode' do
            let(:item12_params) { super().merge(open_mode: true) }

            before do
              item12

              items = Structure::UserItemsSelector.new(course.node, user_id).items
              expect(items).to eq [item_branch1, item12]
            end

            # Additional scopes are applied for anonymous users,
            # only making open mode items accessible.
            it_behaves_like 'a visitable item', :item12
          end
        end
      end
    end
  end
end
