# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.enrolled_for', type: :model do
  subject(:scope) { described_class.enrolled_for(user) }

  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session(user_session) }

  context 'for anonymous users' do
    let(:user_session) { {'user' => {'anonymous' => true}} }

    it 'is empty when there are no courses' do
      expect(scope).to be_empty
    end

    it 'does not include active courses' do
      create(:course, :active)

      expect(scope).to be_empty
    end

    it 'does not include deleted courses' do
      create(:course, :active, :deleted)

      expect(scope).to be_empty
    end

    it 'does not include courses that should be hidden on the course list' do
      create(:course, :active, show_on_list: false)

      expect(scope).to be_empty
    end

    it 'does not include hidden courses' do
      create(:course, :active, :hidden)

      expect(scope).to be_empty
    end

    it 'does not include courses in preparation' do
      create(:course, :preparing)

      expect(scope).to be_empty
    end

    it 'does not include group-restricted courses' do
      create(:course, :active, groups: ['partners'])

      expect(scope).to be_empty
    end
  end

  context 'for registered users' do
    let(:user_id) { generate(:user_id) }
    let(:user_session) do
      {
        'masqueraded' => false,
        'user_id' => user_id,
        'user' => {
          'anonymous' => false,
          'language' => I18n.locale,
          'preferred_language' => I18n.locale,
        },
      }
    end

    it 'is empty when there are no courses' do
      expect(scope).to be_empty
    end

    it 'does not include active courses' do
      create(:course, :active)

      expect(scope).to be_empty
    end

    it 'does not include deleted courses' do
      create(:course, :active, :deleted)

      expect(scope).to be_empty
    end

    it 'does not include deleted courses even when enrolled' do
      course = create(:course, :active, :deleted)
      create(:enrollment, course:, user_id:)

      expect(scope).to be_empty
    end

    it 'does not include courses that should be hidden on the course list' do
      create(:course, :active, show_on_list: false)

      expect(scope).to be_empty
    end

    it 'does not include hidden courses' do
      create(:course, :active, :hidden)

      expect(scope).to be_empty
    end

    it 'includes hidden courses when enrolled' do
      course = create(:course, :active, :hidden)
      create(:enrollment, course:, user_id:)

      expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
    end

    it 'does not include group-restricted courses' do
      create(:course, :active, groups: ['partners'])

      expect(scope).to be_empty
    end

    it 'does not include group-restricted courses when member of the group' do
      create(:course, :active, groups: ['partners'])
      create(:group, name: 'partners', member: user_id)

      expect(scope).to be_empty
    end
  end
end
