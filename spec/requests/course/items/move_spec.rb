# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Move', type: :request do
  let(:user_id) { generate(:user_id) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access course.content.edit] }
  let(:params) { {} }

  before do
    stub_user_request(id: user_id, permissions:)
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json([])
    Stub.request(:course, :get, '/next_dates', query: hash_including(course_id: course.id))
      .to_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json([section_resource])
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  context 'legacy courses' do
    subject(:move_item) do
      post "/courses/#{course['course_code']}/sections/#{section['id']}/items/#{item_resource['id']}/move",
        headers:,
        params:
    end

    let(:course) { create(:course_legacy) }
    let(:section) { create(:section_legacy, course:) }
    let(:item_resource) { build(:'course:item', content_type: 'rich_text', open_mode: false) }

    before do
      Stub.request(:course, :get, "/items/#{item_resource['id']}").to_return Stub.json(item_resource)
      Stub.request(:course, :get, '/items', query: hash_including(section_id: section.id))
        .to_return Stub.json([])
    end

    describe 'when an item is moved' do
      let(:params) { {position: 5} }
      let!(:item_update_request) do
        Stub.request(
          :course, :put, "/items/#{item_resource['id']}",
          # Add one as client items are indexed starting at zero while
          # service starts at one
          body: hash_including(position: 6)
        ).to_return Stub.json({id: item_resource['id']}, status: 201)
      end

      it 'requests the corresponding position' do
        move_item
        expect(item_update_request).to have_been_requested
      end
    end
  end

  context 'courses with nodes' do
    subject(:move_item) do
      post "/courses/#{course.id}/sections/#{section.id}/items/#{item_2.id}/move",
        headers:,
        params:
    end

    let(:course) { create(:course) }
    let(:section) { create(:section, course: course) }
    let!(:item_1) { create(:item, section:) }
    let!(:item_2) { create(:item, section:) }
    let!(:item_3) { create(:item, section:) }
    let(:item) { item_2 }
    let(:item_resource) { build(:'course:item', id: item_2.id, section_id: section.id, course_id: course.id) }

    before do
      Stub.request(:course, :get, "/items/#{item.id}").to_return Stub.json(item_resource)
      Stub.request(:course, :get, '/items', query: {section_id: section.id}).to_return Stub.json([])
      Stub.request(:course, :get, "/courses/#{course.id}").to_return Stub.json(course_resource)
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
          post "/courses/#{course.id}/sections/#{section.id}/items/#{item_1.id}/move",
            headers:,
            params:
        end

        let(:item) { item_1 }
        let(:params) { {left_sibling: item_2.node.id, right_sibling: item_3.node.id} }

        it 'updates its position accordingly' do
          expect { move_item }.to change { item_1.node.reload.right_sibling }.from(item_2.node).to(item_3.node)
            .and change { item_1.node.reload.left_sibling }.from(nil).to(item_2.node)
        end
      end
    end

    describe 'when an item is moved to a new section' do
      let(:new_section) { create(:section, course: course) }

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
