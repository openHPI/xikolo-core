# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Tag, type: :model do
  it 'has a valid factory' do
    expect(create(:'pinboard_service/explicit_tag')).to be_valid
  end

  describe '#by_name' do
    before { create(:'pinboard_service/definition_tag') }

    it 'queries tags case-insensitive' do
      expect(PinboardService::Tag.by_name('Definition').size).to eq(1)
      expect(PinboardService::Tag.by_name('definition').size).to eq(1)
    end
  end

  context 'uniqueness' do
    let!(:implicit_tag) { create(:'pinboard_service/new_implicit_tag') }
    let(:attrs) do
      {
        name: implicit_tag.name,
          course_id: implicit_tag.course_id,
          referenced_resource: implicit_tag.referenced_resource,
      }
    end

    it 'only allows unique tag names in the same context' do
      expect { PinboardService::ImplicitTag.create(attrs) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows re-using tag names in different contexts' do
      expect { PinboardService::ImplicitTag.create(attrs.merge(course_id: SecureRandom.uuid)) }
        .not_to raise_error
    end
  end
end
