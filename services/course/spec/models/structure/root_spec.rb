# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Structure::Root, type: :model do
  subject(:node) { described_class.create!(course:) }

  let(:course) { create(:'course_service/course') }

  it { is_expected.to be_valid }
end
