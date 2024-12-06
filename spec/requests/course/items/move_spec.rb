# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Move', type: :request do
  subject(:move_item) do
    post "/courses/#{course['course_code']}/sections/#{section['id']}/items/#{item['id']}/move",
      headers:,
      params:
  end

  let(:user_id) { generate(:user_id) }
  let(:db_course) { create(:course_legacy) }
  let(:course) { build(:'course:course', id: db_course.id, course_code: db_course.course_code) }
  let(:section) { build(:'course:section', course_id: course['id']) }
  let(:item) { build(:'course:item', content_type: 'rich_text', open_mode: false) }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access course.content.edit] }
  let(:params) { {} }

  before do
    stub_user_request(id: user_id, permissions:)
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course['id'], user_id:}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including(course_id: course['id'])
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, "/sections/#{section['id']}"
    ).to_return Stub.json(section)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course['id']}
    ).to_return Stub.json([section])
    Stub.request(:course, :get, "/courses/#{course['course_code']}")
      .to_return Stub.json(course)
    Stub.request(:course, :get, "/items/#{item['id']}")
      .to_return Stub.json(item)
    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section['id'])
    ).to_return Stub.json([])
  end

  context 'legacy courses' do
    describe 'when an item is moved' do
      let(:params) { {position: 5} }
      let!(:item_update_request) do
        Stub.request(
          :course, :put, "/items/#{item['id']}",
          # Add one as client items are indexed starting at zero while
          # service starts at one
          body: hash_including(position: 6)
        ).to_return Stub.json({id: item['id']}, status: 201)
      end

      it 'requests the corresponding position' do
        move_item
        expect(item_update_request).to have_been_requested
      end
    end
  end

  context 'courses with nodes' do
    subject(:move_item) do
      post "/courses/#{db_course.id}/sections/#{section.id}/items/#{item_2.id}/move",
        headers:,
        params:
    end

    let(:db_course) { create(:course) }
    let(:section) { create(:section, course: db_course) }
    let!(:item_1) { create(:item, section:) }
    let!(:item_2) { create(:item, section:) }
    let!(:item_3) { create(:item, section:) }

    before do
      Stub.request(:course, :get, "/courses/#{db_course.id}")
        .to_return Stub.json(course)
    end

    describe 'when an item is moved within its section' do
      describe 'and placed at the top' do
        let(:params) { {left_sibling: nil, right_sibling: item_1.node.id} }

        it 'updates its position accordingly' do
          expect { move_item }.to change { item_2.node.reload.right_sibling }.from(item_3.node).to(item_1.node)
            .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(nil)
        end
      end

      describe 'and placed at the bottom' do
        let(:params) { {left_sibling: item_3.node.id, right_sibling: nil} }

        it 'updates its position accordingly' do
          expect { move_item }.to change { item_2.node.reload.right_sibling }.from(item_3.node).to(nil)
            .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(item_3.node)
        end
      end

      describe 'and placed between other items' do
        subject(:move_item) do
          post "/courses/#{db_course.id}/sections/#{section.id}/items/#{item_1.id}/move",
            headers:,
            params:
        end

        let(:params) { {left_sibling: item_2.node.id, right_sibling: item_3.node.id} }

        it 'updates its position accordingly' do
          expect { move_item }.to change { item_1.node.reload.right_sibling }.from(item_2.node).to(item_3.node)
            .and change { item_1.node.reload.left_sibling }.from(nil).to(item_2.node)
        end
      end
    end

    describe 'when an item is moved to a new section' do
      let(:new_section) { create(:section, course: db_course) }

      describe 'and the section is empty' do
        let(:params) { {left_sibling: nil, right_sibling: nil, new_section_node_id: new_section.node.id} }

        it 'updates its position accordingly' do
          expect { move_item }.to change { item_2.reload.section_id }.from(section.id).to(new_section.id)
            .and change { item_2.node.reload.parent_id }.from(section.node.id).to(new_section.node.id)
            .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(nil)
            .and change { item_2.node.reload.right_sibling }.from(item_3.node).to(nil)
        end
      end

      describe 'and the section is not empty' do
        let(:new_item_1) { create(:item, section: new_section) }
        let(:new_item_2) { create(:item, section: new_section) }

        describe 'and it is placed at the top' do
          let(:params) { {left_sibling: nil, right_sibling: new_item_1.node.id, new_section_node_id: new_section.node.id} }

          it 'updates its position accordingly' do
            expect { move_item }.to change { item_2.reload.section_id }.from(section.id).to(new_section.id)
              .and change { item_2.node.reload.parent_id }.from(section.node.id).to(new_section.node.id)
              .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(nil)
              .and change { item_2.node.reload.right_sibling }.from(item_3.node).to(new_item_1.node)
          end
        end

        describe 'and it is placed at the bottom' do
          let(:params) { {left_sibling: new_item_2.node.id, right_sibling: nil, new_section_node_id: new_section.node.id} }

          it 'updates its position accordingly' do
            expect { move_item }.to change { item_2.reload.section_id }.from(section.id).to(new_section.id)
              .and change { item_2.node.reload.parent_id }.from(section.node.id).to(new_section.node.id)
              .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(new_item_2.node)
              .and change { item_2.node.reload.right_sibling }.from(item_3.node).to(nil)
          end
        end

        describe 'and it is placed between other items' do
          let(:params) { {left_sibling: new_item_1.node.id, right_sibling: new_item_2.node.id, new_section_node_id: new_section.node.id} }

          it 'updates its position accordingly' do
            expect { move_item }.to change { item_2.reload.section_id }.from(section.id).to(new_section.id)
              .and change { item_2.node.reload.parent_id }.from(section.node.id).to(new_section.node.id)
              .and change { item_2.node.reload.left_sibling }.from(item_1.node).to(new_item_1.node)
              .and change { item_2.node.reload.right_sibling }.from(item_3.node).to(new_item_2.node)
          end
        end
      end
    end
  end
end
