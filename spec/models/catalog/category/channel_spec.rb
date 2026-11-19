# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Category::Channel, type: :model do
  subject(:category) { described_class.new channel }

  let(:channel) { create(:'course_service/channel') }

  it 'includes active courses' do
    course = create(:course, :active, channels: [channel])
    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include courses without channel' do
    create(:course, :active)

    expect(category.courses).to be_empty
  end

  it 'does not include courses from other channels' do
    create(:course, :active, :with_channel)

    expect(category.courses).to be_empty
  end

  it 'includes courses that should be hidden on the course list' do
    create(:course, :active, title: 'Course not listed', placement: [], channels: [channel])

    expect(category.courses).to be_empty
  end

  it 'does not include hidden courses' do
    create(:course, :active, :hidden, channels: [channel])

    expect(category.courses).to be_empty
  end

  it 'does not include courses in preparation' do
    create(:course, :preparing, channels: [channel])

    expect(category.courses).to be_empty
  end

  it 'includes self-paced courses' do
    course = create(:course, :self_paced, channels: [channel])
    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include group-restricted courses' do
    create(:course, :active, groups: ['partners'], channels: [channel])

    expect(category.courses).to be_empty
  end

  context 'when there are lots of matching courses' do
    before do
      create_list(:course, 3, :upcoming, channels: [channel])
      create_list(:course, 2, :active, channels: [channel])
      create_list(:course, 1, :self_paced, channels: [channel])
    end

    it 'shows at most 4 courses, self-paced ones first' do
      expect(category.courses.length).to eq 4

      expect(category.courses).to match [
        an_object_having_attributes(started?: true, over?: true),
        an_object_having_attributes(started?: true, over?: false),
        an_object_having_attributes(started?: true, over?: false),
        an_object_having_attributes(started?: false),
      ]
    end
  end
end
