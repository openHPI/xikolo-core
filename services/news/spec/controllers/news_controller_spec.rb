# frozen_string_literal: true

require 'spec_helper'

def decorate(news)
  NewsDecorator.new(news).as_json(api_version: 1).stringify_keys
end

describe NewsController, type: :controller do
  let!(:news) { create(:news, :published) }

  let(:json) { JSON.parse response.body }
  let(:rt_language) { 'de' }

  describe 'GET index' do
    subject(:index) { get :index, params: }

    let(:params) { {} }
    let(:default_params) { {} }
    let(:rt_language) { 'en' }

    before do
      Stub.request(
        :course, :get, '/enrollments',
        query: {user_id: params[:user_id]}
      ).to_return Stub.json([
        {id: '00000001-3100-4444-9999-000000000001', course_id: news.course_id},
      ])
    end

    it { is_expected.to have_http_status :ok }

    it 'returns a list' do
      index
      expect(json.size).to eq(1)
    end

    context 'for a course' do
      let(:params) { super().merge! course_id: news.course_id }
      let(:other_course_id) { SecureRandom.uuid }

      before do
        # Create other announcements (one global, one for another course) so
        # that we can verify these are not included in the returned results.
        create(:news, :global, :published)
        create(:news, :published, course_id: other_course_id)
      end

      it { is_expected.to have_http_status :ok }

      it 'returns only the news for this course' do
        index
        expect(json.size).to eq(1)
        expect(json[0]).to eq(decorate(news.reload))
      end

      context 'when requesting user-specific information' do
        let(:params) { super().merge(user_id: SecureRandom.uuid) }

        context 'and the user is enrolled in the requested course' do
          it 'returns only the news for this course' do
            index
            expect(json.size).to eq(1)
            expect(json[0]['id']).to eq news.id
          end
        end

        context 'and the user is not enrolled in the requested course' do
          let(:params) { super().merge(course_id: other_course_id) }

          it 'returns no announcements' do
            index
            expect(json).to be_empty
          end
        end
      end
    end

    context 'for a user_id' do
      let!(:news) { create(:news, :published) }
      let(:params) { super().merge(user_id:) }
      let(:user_id) { '00000000-0000-4444-9999-000000000127' }

      context 'that has visited the announcement' do
        before { news.read_states.create(user_id:) }

        it { is_expected.to have_http_status :ok }

        it 'returns a list' do
          index
          expect(json.size).to eq(1)
        end

        it 'lists the announcement as read' do
          index
          expect(json[0]['read']).to be true
        end
      end

      context 'when another user has visited the announcement' do
        before { news.read_states.create(user_id: '00000000-0000-4444-9999-000000000123') }

        it { is_expected.to have_http_status :ok }

        it 'returns a list' do
          index
          expect(json.size).to eq(1)
        end

        it 'lists the announcement as unread' do
          index
          expect(json[0]['read']).to be false
        end
      end

      context 'when including global news' do
        let(:params) { super().merge(global: 'true') }
        let!(:global_news) { create(:news, :global, :published) }
        let!(:restricted_global_news) { create(:news, :global, :published, audience: 'xikolo.affiliated') }
        let(:user_groups) { [{name: 'course.foo1.students'}] }

        before do
          Stub.service(:account, build(:'account:root'))
          Stub.request(:account, :get, '/groups', query: hash_including(user: user_id))
            .to_return Stub.json(user_groups)
          Stub.request(:account, :get, "/users/#{user_id}")
            .to_return Stub.json({permissions_url: "/users/#{user_id}/permissions"})
          Stub.request(:account, :get, "/users/#{user_id}/permissions")
            .to_return Stub.json([])
        end

        it 'includes un-restricted global news' do
          index
          expect(json.pluck('id')).to contain_exactly(news.id, global_news.id)
        end

        context 'when the user is in a restricted group' do
          let(:user_groups) { [{name: 'course.foo1.students'}, {name: 'xikolo.affiliated'}] }

          it "also includes that group's restricted global news" do
            index
            expect(json.pluck('id')).to contain_exactly(news.id, global_news.id, restricted_global_news.id)
          end
        end
      end
    end

    describe 'order' do
      context 'latest first' do
        let!(:news_list) { create_list(:news, 4) }
        let!(:news) { create(:news) }

        describe 'json' do
          it 'has 5 items' do
            index
            expect(json.size).to eq(5)
          end

          it 'is sorted' do
            index
            sorted_news = (news_list << news).sort_by!(&:publish_at).reverse!.pluck('id')
            expect(json.pluck('id')).to match_array sorted_news
          end
        end
      end
    end

    context 'with filter' do
      before do
        create_list(:news, 5)

        # other course news:
        create(:news, course_id: SecureRandom.uuid)

        # other restricted global news:
        create(:news, :global, :published, audience: 'xikolo.affiliated')
      end

      let(:news) { create(:news) }
      let!(:home_news) { create(:news, show_on_homepage: true) }
      let!(:global_news) { create(:news, course_id: nil) }
      let!(:global_home_news) { create(:news, course_id: nil, show_on_homepage: true) }
      let!(:future_global_news) { create(:news, :global, publish_at: 2.days.from_now) }
      let!(:published_global_news) { create(:news, :global, publish_at: 2.days.ago) }

      describe 'global news' do
        let(:params) { super().merge(global: 'true') }

        it 'filters the right ones' do
          index
          expect(json).to contain_exactly(decorate(global_news), decorate(global_home_news), decorate(future_global_news), decorate(published_global_news))
        end
      end

      describe 'only public global news' do
        let(:params) { super().merge(global: 'true', published: 'true') }

        it 'does not include future news' do
          index
          expect(json).not_to include([decorate(future_global_news)])
          expect(json).to match([decorate(published_global_news)])
        end
      end

      describe 'news for all courses' do
        let(:params) { super().merge(all_courses: 'true') }

        it 'filters all except global news' do
          index
          expect(json.size).to eq(8)
          expect(json.pluck('course_id')).to all(be_present)
        end
      end

      describe 'homepage news' do
        context 'those that should be on homepage' do
          let(:params) { super().merge(only_homepage: 'true') }

          it 'filters the right one' do
            index
            expect(json).to contain_exactly(decorate(home_news), decorate(global_home_news))
          end
        end

        context 'those that should not be on homepage' do
          let(:params) { super().merge(only_homepage: 'false') }

          it 'filters' do
            index
            expect(json).not_to include([decorate(home_news), decorate(global_home_news)])
          end
        end
      end

      describe 'global homepage news (combined filters)' do
        let(:params) { super().merge(only_homepage: 'true', global: 'true') }

        it 'filters the right one' do
          index
          expect(json).to contain_exactly(decorate(global_home_news))
        end
      end
    end

    context 'global read count' do
      let(:params) { super().merge(global_read_count: 'true') }
      let!(:news) { create(:news, :published, :read) }

      it { is_expected.to have_http_status :ok }

      it 'returns a list' do
        index
        expect(json.size).to eq(1)
      end

      it 'answers with news resources' do
        index
        expect(json[0]).to eq(NewsDecorator.new(news.reload).as_json(api_version: 1).stringify_keys.merge!('read_count' => 1))
      end
    end
  end
end
