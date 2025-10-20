# frozen_string_literal: true

require 'spec_helper'

# We are overriding Rails' STI type column name resolution, to introduce
# symbolic names for the subtypes of Node. These names can be more easily
# mapped / changed to different classes. This functionality is tested here.
describe 'Structure::Node: Single Table Inheritance', type: :model do
  let(:course) { create(:'course_service/course') }

  it "stores a symbolic name to identify a node's concrete type" do
    node = Structure::Root.create!(course:)

    expect(node.type).to eq 'root'
  end

  it 'can look up models based on symbolic names' do
    node = Structure::Node.create!(type: 'root', course:)

    typed_node = Structure::Node.find node.id
    expect(typed_node).to be_a Structure::Root
  end

  it 'can not be looked up with a concrete type that does not match' do
    node = Structure::Node.create!(type: 'root', course:)

    expect do
      Structure::Section.find node.id
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
