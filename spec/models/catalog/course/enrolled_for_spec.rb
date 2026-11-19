# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.enrolled_for', type: :model do
  subject(:scope) { described_class.enrolled_for(user) }

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

  context 'for anonymous users' do
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
      create(:course, :active, placement: [])

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
      create(:course, :active, groups: ['xikolo.partners'])

      expect(scope).to be_empty
    end
  end

  context 'for registered users' do
    let(:account_user) { create(:'account_service/user') }
    let(:session) { create(:'account_service/session', user: account_user) }
    let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
    let(:user_id) { account_user.id }

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
      create(:course, :active, placement: [])

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
      create(:course, :active, groups: ['xikolo.partners'])
      group = create(:'account_service/group', name: 'xikolo.partners')
      create(:'account_service/membership', group:, user: account_user)

      expect(scope).to be_empty
    end
  end
end
