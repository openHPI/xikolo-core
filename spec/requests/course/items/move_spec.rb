# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Move', type: :request do
  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }

  let(:permissions) { %w[course.content.access course.content.edit] }
  let(:params) { {} }

  before do
    sign_in(user:)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
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
      post "/learn/#{course['course_code']}/sections/#{section['id']}/items/#{item_resource['id']}/move",
        params:
    end

    let(:course) { create(:course_legacy) }
    let(:section) { create(:section_legacy, course:) }
    # `create(:item, ...)` attaches a content tree node, which legacy
    # sections/courses do not have, so the item is created directly instead.
    let(:item_resource) do
      CourseService::Item.create!(
        section:, title: 'Legacy Item', content: create(:richtext), open_mode: false
      )
    end

    describe 'when an item is moved' do
      let(:params) { {position: 5} }

      it 'sets the corresponding position' do
        move_item
        # Add one as client items are indexed starting at zero while
        # service starts at one
        expect(item_resource.reload.position).to eq 6
      end
    end
  end

  context 'courses with nodes' do
    subject(:move_item) do
      post "/learn/#{course.id}/sections/#{section.id}/items/#{item_2.id}/move",
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
          post "/learn/#{course.id}/sections/#{section.id}/items/#{item_1.id}/move",
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
