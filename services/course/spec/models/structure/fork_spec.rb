# frozen_string_literal: true

require 'spec_helper'

describe Structure::Fork, type: :model do
  # The fork node must have an ID, even if not actually saved to the database,
  # because when assigning children (`fork.children = [branch.node]`), the
  # `parent_id` of each child node will be set to `fork.id`. This will set the
  # `parent_id` of each child node to `nil`, unless an ID is present.
  #
  # As branch nodes do validate that a `parent_id` must be present, the fork
  # will be invalid because its `children` are invalid.
  #
  #     b = Structure::Branch.new(parent_id: "de3d5123-4d08-4871-b4ab-25b045816e37")
  #     b.valid? # => true
  #     b.parent_id # => "de3d5123-4d08-4871-b4ab-25b045816e37"
  #
  #     s = Structure::Fork.new
  #     s.children = [b]
  #     s.valid? # => false
  #     s.errors.messages # => {:children=>["is invalid"], ...}
  #
  #     s.children[0] # => #<Structure::Branch ... parent_id: nil, ...>
  #
  # Adding invalid items to an association will always make the parent object
  # invalid, it will contain the error above.
  #
  subject(:node) do
    described_class.new(
      id: '7f653cd4-6ef2-41c2-bad4-4154a1eda577',
      course:,
      fork:
    )
  end

  let(:course) { create(:'course_service/course', :with_content_tree) }
  let(:fork) { create(:'course_service/fork', section:, course:) }
  let(:section) { create(:'course_service/section', course:) }

  let(:uuid) { '041f16f2-f484-4da2-8cbe-6f53aaeecee1' }
  let(:test_branch) { test_fork.branches[0] }
  let(:test_fork) { create(:'course_service/fork', section:, course:, content_test: fork.content_test) }
  let(:test_item) { create(:'course_service/item', section:) }
  let(:test_section) { create(:'course_service/section', course:) }

  describe 'validation' do
    it { is_expected.to accept_values_for :parent, test_section.node }
    it { is_expected.not_to accept_values_for :parent, nil, test_fork.node, test_branch.node, test_item.node }

    it { is_expected.to accept_values_for :children, [test_branch.node] }
    it { is_expected.not_to accept_values_for :children, [test_fork.node], [test_section.node], [test_item.node] }
  end
end
