# frozen_string_literal: true

require 'spec_helper'

describe Collabspace::FilePresenter do
  subject(:file_presenter) { described_class.new file, current_user, collabspace }

  let(:file) do
    {
      id: file_id,
      title: 'Awesome file',
      creator_id: generate(:user_id),
    }.stringify_keys # It's a Restiy resource!
  end
  let(:file_id) { SecureRandom.uuid }
  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'features' => {},
      'user' => {'anonymous' => false},
      'user_id' => current_user_id
    )
  end
  let(:current_user_id) { generate(:user_id) }
  let(:permissions) { [] }
  let(:collabspace) { {id: collabspace_id}.stringify_keys } # It's a Restiy resource!
  let(:collabspace_id) { SecureRandom.uuid }
  let(:membership) { {status: 'regular'} }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.service(:collabspace,
      memberships_url: '/memberships{?user_id,status,kind,course_id}')

    Stub.request(:collabspace, :get, '/memberships',
      query: {
        collab_space_id: collabspace_id,
        user_id: current_user_id,
      }).to_return Stub.json([membership])
  end

  describe '#title' do
    subject(:title) { file_presenter.title }

    it { is_expected.to eq 'Awesome file' }
  end

  describe '#can_delete?' do
    subject { super().can_delete? }

    context 'as any user' do
      it { is_expected.to be_falsey }
    end

    context 'as author of the file' do
      let(:file) do
        {
          id: file_id,
          title: 'Awesome file',
          creator_id: current_user_id,
        }.stringify_keys # It's a Restiy resource!
      end

      it { is_expected.to be_truthy }
    end

    context 'with file manage permissions' do
      let(:permissions) { %w[collabspace.file.manage] }

      it { is_expected.to be_truthy }
    end

    context 'as privileged user in collabspace' do
      context '(admin)' do
        let(:membership) { {status: 'admin'} }

        it { is_expected.to be_truthy }
      end

      context '(mentor)' do
        let(:membership) { {status: 'mentor'} }

        it { is_expected.to be_truthy }
      end
    end
  end
end
