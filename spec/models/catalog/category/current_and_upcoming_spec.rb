# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Category::CurrentAndUpcoming, type: :model do
  subject(:category) { described_class.new }

  it 'includes active courses' do
    course = create(:course, :active)

    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include deleted courses' do
    create(:course, :active, :deleted)

    expect(category.courses).to be_empty
  end

  it 'does not include courses that should be hidden on the course list' do
    create(:course, :active, show_on_list: false)

    expect(category.courses).to be_empty
  end

  it 'does not include hidden courses' do
    create(:course, :active, :hidden)

    expect(category.courses).to be_empty
  end

  it 'does not include courses in preparation' do
    create(:course, :preparing)

    expect(category.courses).to be_empty
  end

  it 'does not include archived courses' do
    create(:course, :archived)

    expect(category.courses).to be_empty
  end

  it 'does not include group-restricted courses' do
    create(:course, :active, groups: ['partners'])

    expect(category.courses).to be_empty
  end

  context 'when there are lots of matching courses' do
    before do
      create_list(:course, 3, :active)
      create_list(:course, 6, :upcoming)
    end

    it 'limits to 4 courses by default, current ones first' do
      expect(category.courses.length).to eq 4

      expect(category.courses).to match [
        an_object_having_attributes(started?: true),
        an_object_having_attributes(started?: true),
        an_object_having_attributes(started?: true),
        an_object_having_attributes(started?: false),
      ]
    end

    it 'can be configured to a different number of courses' do
      category = described_class.new(max: 6)
      expect(category.courses.length).to eq 6
    end
  end
end
