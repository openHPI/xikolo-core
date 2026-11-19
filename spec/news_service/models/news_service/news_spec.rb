# frozen_string_literal: true

require 'spec_helper'

describe NewsService::News, type: :model do
  subject { news }

  let(:attributes) { {} }
  let(:news) { create(:'news_service/news', attributes) }

  it { is_expected.to be_valid }

  describe 'validations' do
    context 'global announcements' do
      let(:news) { create(:'news_service/news', :global) }

      it { is_expected.to accept_values_for(:audience, 'xikolo.affiliated', nil) }
    end

    context 'course announcements' do
      it { is_expected.not_to accept_values_for(:audience, 'xikolo.affiliated') }
    end
  end

  describe 'scopes' do
    describe '#published' do
      subject(:relation) { described_class.published }

      let!(:published) { create(:'news_service/news', :published) }

      before { create(:'news_service/news') }

      it { is_expected.to contain_exactly(published) }
    end

    describe '#unread_by' do
      subject(:relation) { described_class.unread_by(user_id) }

      let(:user_id) { generate(:user_id) }
      let!(:unread) { create(:'news_service/news', :published) }

      before do
        create(:'news_service/news', :published, :read, read_by_users: [user_id])
        create(:'news_service/news', publish_at: described_class::MARK_AS_READ_BEFORE - 1.day)
      end

      it 'excludes the news read by the user and those from before read tracking' do
        expect(relation).to contain_exactly(unread)
      end

      it 'includes the news read by other users only' do
        create(:'news_service/news', :published, :read)

        expect(relation.count).to eq 2
      end
    end

    describe '#for_groups' do
      subject(:relation) { described_class.for_groups(user: user_id) }

      let(:user_id) { generate(:user_id) }
      let!(:global_announcement) { create(:'news_service/news', :global) }
      let!(:matching_restricted_announcement) { create(:'news_service/news', :global, audience: 'matching_group') }
      let!(:other_restricted_announcement) { create(:'news_service/news', :global, audience: 'other_group') }
      let(:user_groups_response) do
        Stub.json([
          {name: 'matching_group'},
          {name: 'admins'},
        ])
      end
      let(:user_permissions_response) { Stub.json([]) }

      before do
        # Create another course announcement to ensure unwanted announcements
        # do not show up in the various responses.
        create(:'news_service/news')

        Stub.request(:account, :get, '/groups', query: hash_including(user: user_id))
          .to_return user_groups_response
        Stub.request(:account, :get, "/users/#{user_id}")
          .to_return Stub.json({permissions_url: "/account_service/users/#{user_id}/permissions"})
        Stub.request(:account, :get, "/users/#{user_id}/permissions")
          .to_return user_permissions_response
      end

      it "returns all announcements targeted at any of the user's groups" do
        expect(relation).to contain_exactly(global_announcement, matching_restricted_announcement)
      end

      context 'when the user has no groups' do
        let(:user_groups_response) { Stub.json([]) }

        it { is_expected.to eq [global_announcement] }
      end

      context 'when the user has no groups, but is an admin' do
        let(:user_groups_response) { Stub.json([]) }
        let(:user_permissions_response) do
          Stub.json(['news.announcement.show'])
        end

        it 'returns all announcements targeted at any user group' do
          expect(relation).to contain_exactly(global_announcement, matching_restricted_announcement, other_restricted_announcement)
        end
      end

      context 'when fetching user groups fails' do
        let(:user_groups_response) { Stub.response(status: 502) }

        it { is_expected.to eq [global_announcement] }
      end

      context 'when fetching user permissions fails' do
        let(:user_permissions_response) { Stub.response(status: 502) }

        it 'assumes a normal user and applies group restrictions' do
          expect(relation).to contain_exactly(global_announcement, matching_restricted_announcement)
        end
      end

      context 'without a user ID' do
        let(:user_id) { nil }

        it { is_expected.to eq [global_announcement] }
      end
    end
  end

  describe '#translated_titles' do
    subject(:titles) { news.translated_titles }

    it { is_expected.to be_a Hash }

    it 'has one item' do
      expect(titles.size).to eq 1
    end

    it { is_expected.to have_key 'en' }

    context 'with a German translation' do
      let(:news) { create(:'news_service/news', :with_german_translation) }

      it { is_expected.to be_a Hash }

      it 'has two items' do
        expect(titles.size).to eq 2
      end

      it { is_expected.to have_key 'en' }
      it { is_expected.to have_key 'de' }
    end
  end
end
