# frozen_string_literal: true

require 'spec_helper'

class UserTestsHelperTestClass
  include UserTestsHelper
end

describe UserTestsHelper, type: :helper do
  describe 'assign a user to an experiment' do
    let(:identifier) { 'new_test' }
    let(:user) { Xikolo::Common::Auth::CurrentUser.from_session(session) }
    let(:session) do
      {
        'user' => {'anonymous' => false},
        'features' => {'my_flipper.platform_feature' => true},
      }
    end

    before do
      Stub.service(
        :grouping,
        user_assignments_url: '/user_assignment'
      )
    end

    context 'for anonymous user' do
      subject(:assignment) do
        UserTestsHelperTestClass.new
          .experiment(identifier).assign!(user)
      end

      let(:session) { super().merge('user' => {'anonymous' => true}) }
      let!(:service_stub) do
        Stub.request(
          :grouping, :post, '/user_assignment',
          query: hash_including({}),
          body: hash_including({})
        )
      end

      it 'allows verifying the user\'s features' do
        assignment
        expect(service_stub).not_to have_been_requested
        expect(assignment.feature?('my_flipper.platform_feature')).to be true
        expect(assignment.feature?('my_flipper.other')).to be false
      end
    end

    context 'w/o excluded groups' do
      subject(:assignment) do
        UserTestsHelperTestClass.new
          .experiment(identifier).assign!(user)
      end

      let!(:assignment_stub) do
        Stub.request(
          :grouping, :post, '/user_assignment',
          query: {user_id: nil},
          body: {identifier:}
        ).to_return Stub.json({
          features: {
            'my_flipper.new_test': true,
            'my_flipper.new_functionality': true,
          },
        })
      end

      it 'allows verifying the users\'s (new) features' do
        assignment
        expect(assignment.feature?('my_flipper.new_test')).to be true
        expect(assignment.feature?('my_flipper.new_functionality')).to be true
        expect(assignment.feature?('my_flipper.platform_feature')).to be true
        expect(assignment.feature?('my_flipper.other')).to be false
        expect(assignment_stub).to have_been_requested
      end

      it 'does not exclude any groups' do
        assignment
        expect(assignment_stub).to have_been_requested
      end

      context 'when the user is already assigned to a group' do
        let(:session) do
          super().merge(
            'features' => {
              'my_flipper.platform_feature' => true,
              'my_flipper.new_test' => true,
              'my_flipper.new_functionality' => true,
            }
          )
        end
        let!(:assignment_stub) do
          Stub.request(
            :grouping, :post, '/user_assignment',
            query: {user_id: nil},
            body: {identifier:}
          ).to_return Stub.json({features: {}})
        end

        it 'allows verifying the users\'s (existing) features' do
          assignment
          expect(assignment.feature?('my_flipper.new_test')).to be true
          expect(assignment.feature?('my_flipper.new_functionality')).to be true
          expect(assignment.feature?('my_flipper.platform_feature')).to be true
          expect(assignment.feature?('my_flipper.other')).to be false
          expect(assignment_stub).to have_been_requested
        end
      end
    end

    context 'w/ excluded groups' do
      subject(:assignment) do
        UserTestsHelperTestClass.new
          .experiment(identifier).assign!(user, exclude_groups: excluded_groups)
      end

      let(:excluded_groups) { %w[1] }
      let!(:assignment_stub) do
        Stub.request(
          :grouping, :post, '/user_assignment',
          query: {user_id: nil},
          body: {identifier:, exclude_groups: excluded_groups}
        ).to_return Stub.json({features: {'my_flipper.new_functionality': true}})
      end

      it 'allows verifying the users\'s (new) features' do
        assignment
        expect(assignment.feature?('my_flipper.new_test')).to be false
        expect(assignment.feature?('my_flipper.new_functionality')).to be true
        expect(assignment.feature?('my_flipper.platform_feature')).to be true
        expect(assignment_stub).to have_been_requested
      end

      it 'excludes the specified group' do
        assignment
        expect(assignment_stub).to have_been_requested
      end
    end
  end
end
