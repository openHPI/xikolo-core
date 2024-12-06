# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Category::Channel, type: :model do
  subject(:category) { described_class.new channel }

  let(:channel) { create(:channel) }

  it 'includes active courses' do
    course = create(:course, :active, channel:)

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
    create(:course, :active, title: 'Course not listed', show_on_list: false, channel:)

    expect(category.courses).to contain_exactly(an_object_having_attributes(title: 'Course not listed'))
  end

  it 'does not include hidden courses' do
    create(:course, :active, :hidden, channel:)

    expect(category.courses).to be_empty
  end

  it 'does not include courses in preparation' do
    create(:course, :preparing, channel:)

    expect(category.courses).to be_empty
  end

  it 'includes archived courses' do
    course = create(:course, :archived, channel:)

    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include group-restricted courses' do
    create(:course, :active, groups: ['partners'], channel:)

    expect(category.courses).to be_empty
  end

  context 'when there are lots of matching courses' do
    before do
      create_list(:course, 3, :upcoming, channel:)
      create_list(:course, 2, :active, channel:)
      create_list(:course, 1, :archived, channel:)
    end

    it 'shows at most 4 courses, archived ones first' do
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
