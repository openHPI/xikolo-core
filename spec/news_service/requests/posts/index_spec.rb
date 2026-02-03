# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Posts: Index', type: :request do
  subject(:resource) { service.rel(:posts).get(params).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }
  let(:params) { {} }
  let!(:global_announcement) { create(:'news_service/news', :global, :published) }
  let!(:unpublished_announcement) { create(:'news_service/news', :global, publish_at: 2.days.from_now) }
  let!(:restricted_announcement_1) { create(:'news_service/news', :global, :published, audience: 'xikolo.affiliated') }

  before do
    # Create another course announcement and restricted global announcement to
    # ensure unwanted announcements do not show up in the various responses.
    create(:'news_service/news', :published)
    create(:'news_service/news', :global, :published, audience: 'xikolo.partners')
  end

  it { is_expected.to respond_with :ok }

  it 'returns all global, non-restricted announcements (even unpublished)' do
    expect(resource.pluck('id')).to contain_exactly(global_announcement.id, unpublished_announcement.id)
  end

  describe '(json)' do
    it 'includes all required fields' do
      expect(resource).to all have_key('id')
        .and have_key('title')
        .and have_key('text')
        .and have_key('publish_at')
        .and have_key('visual_url')
        .and have_key('audience')
    end
  end

  describe 'with published=true' do
    let(:params) { {**super(), published: true} }

    it 'returns only published global, non-restricted announcements' do
      expect(resource.pluck('id')).to eq [global_announcement.id]
    end
  end

  describe 'with published=false' do
    let(:params) { {**super(), published: false} }

    it 'returns all global, non-restricted announcements' do
      expect(resource.pluck('id')).to contain_exactly(global_announcement.id, unpublished_announcement.id)
    end
  end

  describe 'with different translations' do
    subject(:representation) { resource.find {|row| row['id'] == global_announcement.id } }

    let!(:global_announcement) { create(:'news_service/news', :global, :published, :with_german_translation) }

    context 'with no language set' do
      it 'responds in English (the default)' do
        expect(representation['title']).to eq 'Some title'
        expect(representation['text']).to eq 'A beautiful announcement text'
      end
    end

    context 'when requesting :de language' do
      let(:params) { {**super(), language: :de} }

      it 'responds in German' do
        expect(representation['title']).to eq 'Deutscher Titel'
        expect(representation['text']).to eq 'Deutscher Text'
      end
    end

    context 'when requesting non-existing language' do
      let(:params) { {**super(), language: :xx} }

      it 'responds in English (the default)' do
        expect(representation['title']).to eq 'Some title'
        expect(representation['text']).to eq 'A beautiful announcement text'
      end

      context 'when no English translation exists' do
        before do
          global_announcement.translations.where(locale: 'en').delete_all
        end

        it 'responds with German (the only available translation)' do
          expect(representation['title']).to eq 'Deutscher Titel'
          expect(representation['text']).to eq 'Deutscher Text'
        end
      end
    end
  end

  describe 'with user ID' do
    let(:params) { {**super(), user_id:} }
    let(:user_id) { generate(:user_id) }

    before do
      Stub.request(:account, :get, '/groups', query: hash_including(user: user_id))
        .to_return Stub.json(user_groups)
      Stub.request(:account, :get, "/users/#{user_id}")
        .to_return Stub.json({permissions_url: "/account_service/users/#{user_id}/permissions"})
      Stub.request(:account, :get, "/users/#{user_id}/permissions")
        .to_return Stub.json([])
    end

    context 'when the user is not in a special group' do
      let(:user_groups) { [{name: 'course.foo1.students'}] }

      it 'returns all non-restricted global announcements' do
        expect(resource.pluck('id')).to contain_exactly(global_announcement.id, unpublished_announcement.id)
      end
    end

    context 'when the user is in a special group' do
      let(:user_groups) { [{name: 'course.foo1.students'}, {name: 'xikolo.affiliated'}] }

      it 'returns all global announcements including the matching restricted one' do
        expect(resource.pluck('id')).to contain_exactly(global_announcement.id, unpublished_announcement.id, restricted_announcement_1.id)
      end
    end
  end
end
