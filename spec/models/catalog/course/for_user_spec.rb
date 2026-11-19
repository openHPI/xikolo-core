# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.for_user', type: :model do
  subject(:scope) { described_class.for_user(user) }

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

  context 'for anonymous users' do
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
    let(:account_user) { create(:'account_service/user') }
    let(:session) { create(:'account_service/session', user: account_user) }
    let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
    let(:user_id) { account_user.id }

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

    it 'excludes courses that should be hidden on the course list' do
      create(:course, :active, title: 'Course not listed', placement: [])

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
      let(:account_user) { create(:'account_service/user') }
      let(:user_id) { account_user.id }
      let(:course) { create(:course, :active, groups: %w[xikolo.partners]) }

      before do
        course
        group = AccountService::Group.create!(name: 'xikolo.partners')
        AccountService::Membership.create!(group:, user_id: account_user.id)
      end

      it 'includes group-restricted courses' do
        expect(scope).to contain_exactly(an_object_having_attributes(id: course.id))
      end
    end
  end
end
