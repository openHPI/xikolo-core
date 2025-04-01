# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::SmowlAdapter do
  subject(:proctoring) { described_class.new(course) }

  let(:course) { build(:course, course_code: 'short_course_id') }

  describe '#passed?' do
    subject(:passed) { proctoring.passed?(user) }

    let(:user) { Struct.new(:id).new(user_id) }
    let(:user_id) { '00000001-3100-4444-9999-000000000001' }

    it { is_expected.to be false }
  end
end
