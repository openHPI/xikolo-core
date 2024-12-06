# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Structure::Item, type: :model do
  subject(:node) { described_class.create!(course:, parent:, item:) }

  let(:item) { create(:item) }
  let(:course) { section.course }
  let(:section) { item.section }

  let(:root) { course.create_node! }
  let(:parent) { section.create_node!(course:, parent: root) }

  it { is_expected.to be_valid }
end
