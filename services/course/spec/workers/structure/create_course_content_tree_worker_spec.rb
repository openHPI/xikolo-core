# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Structure::CreateCourseContentTreeWorker, type: :worker do
  subject(:perform) { described_class.new.perform(course.id) }

  let(:course) { create(:'course_service/course', course_code: 'the-course') }

  context 'with existing course content tree' do
    let(:course) { create(:'course_service/course', :with_content_tree, course_code: 'the-course') }

    it 'aborts as the course content tree would be overwritten' do
      skip 'this feature is currently not supported and the worker is unreliable'
      expect { perform }.to raise_error RuntimeError
    end
  end

  it 'creates the course node' do
    skip 'this feature is currently not supported and the worker is unreliable'
    expect { perform }.to change { Structure::Root.where(course:).count }.from(0).to(1)
  end

  context 'with sections and items' do
    let(:s1) { create(:'course_service/section', course:) }
    let(:s2) { create(:'course_service/section', course:) }

    before do
      2.times {|i| create(:'course_service/item', section: s1, title: "1.#{i}") }
      3.times {|i| create(:'course_service/item', section: s2, title: "2.#{i}") }
    end

    it 'creates the course node' do
      skip 'this feature is currently not supported and the worker is unreliable'
      expect { perform }.to change { Structure::Root.where(course:).count }.from(0).to(1)
    end

    it 'creates the section nodes' do
      skip 'this feature is currently not supported and the worker is unreliable'
      expect { perform }.to change { Structure::Section.where(course:).count }.from(0).to(2)
      # Ensure the section nodes have the correct position within the tree.
      expect(course.reload.node.children.pluck(:section_id)).to eq [s1.id, s2.id]
    end

    it 'creates item nodes for the respective sections' do
      skip 'this feature is currently not supported and the worker is unreliable'
      expect { perform }.to change(Structure::Item, :count).from(0).to(5)

      # Ensure the item nodes are assigned to the correct section nodes
      # and have the correct position within the tree.
      items_s1 = Structure::Item.where(course:, parent: s1.node.id)
      expect(items_s1.map(&:item).pluck(:title)).to eq %w[1.0 1.1]
      expect(s1.node.children.pluck(:item_id)).to eq s1.items.pluck(:id)

      items_s2 = Structure::Item.where(course:, parent: s2.node.id)
      expect(items_s2.map(&:item).pluck(:title)).to eq %w[2.0 2.1 2.2]
      expect(s2.node.children.pluck(:item_id)).to eq s2.items.pluck(:id)
    end

    it 'does not affect other courses / their structure nodes' do
      skip 'this feature is currently not supported and the worker is unreliable'
      another_course = create(:'course_service/course', course_code: 'another-course')

      expect { perform }.not_to change { Structure::Root.where(course: another_course).count }
    end
  end
end
