# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Structure::Section, type: :model do
  subject(:node) do
    described_class.create!(course:, parent: root, section:)
  end

  let(:section) { create(:'course_service/section') }
  let(:course) { section.course }

  let(:root) { course.create_node! }

  it { is_expected.to be_valid }
end
