# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Channel, '.not_deleted', type: :model do
  subject(:scope) { described_class.not_deleted }

  let!(:channel) { create(:'course_service/channel') }

  before { create(:'course_service/channel', archived: true) }

  it 'returns only non-archived channels' do
    expect(scope).to contain_exactly(channel)
  end
end
