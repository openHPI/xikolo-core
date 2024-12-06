# frozen_string_literal: true

require 'spec_helper'

describe Tag, type: :model do
  it 'has a valid factory' do
    expect(create(:explicit_tag)).to be_valid
  end

  describe '#by_name' do
    before { create(:definition_tag) }

    it 'queries tags case-insensitive' do
      expect(Tag.by_name('Definition').size).to eq(1)
      expect(Tag.by_name('definition').size).to eq(1)
    end
  end

  context 'uniqueness' do
    let!(:implicit_tag) { create(:new_implicit_tag) }
    let(:attrs) do
      {
        name: implicit_tag.name,
          course_id: implicit_tag.course_id,
          referenced_resource: implicit_tag.referenced_resource,
      }
    end

    it 'only allows unique tag names in the same context' do
      expect { ImplicitTag.create(attrs) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows re-using tag names in different contexts' do
      expect { ImplicitTag.create(attrs.merge(course_id: SecureRandom.uuid)) }
        .not_to raise_error
    end
  end
end
