# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.for_user', type: :model do
  subject(:scope) { described_class.for_user(user) }

  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session(user_session) }

  context 'for anonymous users' do
    let(:user_session) { {'user' => {'anonymous' => true}} }

    it 'is empty when there are no courses' do
      expect(scope).to be_empty
    end

    it 'includes active courses' do
      course = create(:course, :active)

      expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
    end

    it 'does not include deleted courses' do
      create(:course, :active, :deleted)

      expect(scope).to be_empty
    end

    it 'includes courses that should be hidden on the course list' do
      create(:course, :active, title: 'Course not listed', show_on_list: false)

      expect(scope).to contain_exactly(an_object_having_attributes(title: 'Course not listed'))
    end

    it 'does not include hidden courses' do
      create(:course, :active, :hidden)

      expect(scope).to be_empty
    end

    it 'includes courses in preparation' do
      create(:course, :preparing)

      expect(scope).to contain_exactly(an_object_having_attributes(status: 'preparation'))
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

    it 'includes active courses' do
      course = create(:course, :active)

      expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
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

    it 'includes courses that should be hidden on the course list' do
      create(:course, :active, title: 'Course not listed', show_on_list: false)

      expect(scope).to contain_exactly(an_object_having_attributes(title: 'Course not listed'))
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

    it 'includes courses in preparation' do
      create(:course, :preparing)

      expect(scope).to contain_exactly(an_object_having_attributes(status: 'preparation'))
    end

    it 'includes courses in preparation when enrolled' do
      course = create(:course, :preparing)
      create(:enrollment, course:, user_id:)

      expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
    end

    it 'does not include group-restricted courses' do
      create(:course, :active, groups: ['partners'])

      expect(scope).to be_empty
    end

    context 'when user is member of the group' do
      let(:user) { create(:user) }
      let(:course) { create(:course, :active, groups: %w[partners]) }

      before do
        course
        group = create(:group, name: 'partners')
        create(:membership, group:, user:)
      end

      it 'includes group-restricted courses' do
        expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
      end
    end
  end
end
