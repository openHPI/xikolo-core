# frozen_string_literal: true

require 'spec_helper'

describe 'Home: Courses: Index', type: :request do
  subject(:request) do
    get '/courses', headers:, params:
  end

  let(:headers) { {} }
  let(:page) { Capybara.string(response.body) }
  let(:params) { {} }
  let(:cluster) { create(:cluster, :visible, id: 'topic') }
  let(:classifier) { create(:classifier, cluster:, title: 'Databases') }

  let!(:hidden_course) do
    create(:course, title: 'Course 4', status: 'active', hidden: true,
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
  end
  let!(:channel_course) do
    create(:course, :with_channel, status: 'active', title: 'A course with channel',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
  end

  before do
    create(:course, title: 'Course 1', status: 'active', abstract: 'Active course not in a channel',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, title: 'Course 2', status: 'archive', lang: 'de',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, title: 'Course 3', deleted: 'true', lang: 'de',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, status: 'active', title: 'A course with classifier',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1)).tap do |c|
      c.classifiers << classifier
    end
  end

  shared_examples 'ajax request' do
    context 'as an ajax request' do
      let(:headers) { super().merge('X-Requested-With': 'XMLHttpRequest') }
      let(:params) { super().merge(page: 2) }

      # rubocop:disable FactoryBot/ExcessiveCreateList
      before do
        # On page 1 are 'Course 1', 'Course 2', 'A course with classifier', 'A course with channel', and:
        create_list(:course, 8, title: 'Self-paced course on page 1', status: 'archive',
          start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))

        create_list(:course, 12, title: 'Self-paced course on page 2', status: 'archive',
          start_date: DateTime.new(2016, 11, 1), end_date: DateTime.new(2016, 12, 1))
        create_list(:course, 12, title: 'Self-paced course on page 3', status: 'archive',
          start_date: DateTime.new(2017, 11, 1), end_date: DateTime.new(2017, 12, 1))
      end
      # rubocop:enable FactoryBot/ExcessiveCreateList

      it 'renders the courses partial for page 2 with 12 self-paced courses' do
        request
        expect(response.headers['Cache-Control']).to include('no-store')
        expect(response.headers['X-Total-Pages']).to eq '3'
        expect(response.headers['X-Current-Page']).to eq '2'

        expect(response).to render_template partial: '_courses'

        expect(page).to have_content 'Self-paced course on page 2', count: 12

        expect(page).to have_no_content 'Self-paced course on page 1'
        expect(page).to have_no_content 'Self-paced course on page 3'
        expect(page).to have_no_content 'Course 1'
        expect(page).to have_no_content 'Course 2'
        expect(page).to have_no_content 'A course with channel'
        expect(page).to have_no_content 'A course with classifier'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
      end
    end
  end

  context 'as anonymous user' do
    let(:anonymous_session) do
      super().merge(features: {'course_list' => 'true'})
    end

    include_examples 'ajax request'

    it 'lists all public courses' do
      request
      expect(response).to have_http_status :ok
      expect(response).to render_template :index

      expect(page).to have_content 'Course 1'
      expect(page).to have_content 'Course 2'
      expect(page).to have_content 'A course with channel'
      expect(page).to have_content 'A course with classifier'
      expect(page).to have_no_content 'Course 3'
      expect(page).to have_no_content 'Course 4'
    end

    context 'when the params contain an invalid null type' do
      let(:params) do
        super().merge(q: "\u0000")
      end

      it 'ignores the invalid param and successfully renders the page' do
        request
        expect(response).to have_http_status :ok
        expect(response).to render_template :index
      end

      it 'returns all public courses' do
        request
        expect(page).to have_content 'Course 1'
        expect(page).to have_content 'Course 2'
        expect(page).to have_content 'A course with channel'
        expect(page).to have_content 'A course with classifier'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
      end
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:user) { stub_user_request features: {'course_list' => 'true'} }

    before { user }

    include_examples 'ajax request'

    it 'lists all public courses' do
      request
      expect(response).to have_http_status :ok
      expect(response).to render_template :index

      expect(page).to have_content 'Course 1'
      expect(page).to have_content 'Course 2'
      expect(page).to have_content 'A course with channel'
      expect(page).to have_content 'A course with classifier'
      expect(page).to have_no_content 'Course 3'
      expect(page).to have_no_content 'Course 4'
    end

    context 'when enrolled in a hidden course' do
      before do
        create(:enrollment, user_id: user[:id], course_id: hidden_course.id)
      end

      it 'lists that hidden course as well' do
        request

        expect(page).to have_content 'Course 1'
        expect(page).to have_content 'Course 2'
        expect(page).to have_content 'Course 4'
        expect(page).to have_content 'A course with channel'
        expect(page).to have_content 'A course with classifier'
        expect(page).to have_no_content 'Course 3'
      end
    end

    context 'when filtered by text search query' do
      let(:params) { super().merge(q: 'channel') }

      it 'lists only courses matching that query (e.g. in title or abstract)' do
        skip 'Search reindexing of courses does not yet happen in xi-web'

        request

        expect(page).to have_content 'Course 1'
        expect(page).to have_content 'A course with channel'
        expect(page).to have_no_content 'Course 2'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
        expect(page).to have_no_content 'A course with classifier'
      end
    end

    context 'when filtered by channel code' do
      let(:params) { super().merge(channel: channel_course.channel.code) }

      it 'lists only courses belonging to that channel' do
        request

        expect(page).to have_content 'A course with channel'
        expect(page).to have_no_content 'Course 1'
        expect(page).to have_no_content 'Course 2'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
        expect(page).to have_no_content 'A course with classifier'
      end
    end

    context 'when filtered by classifier' do
      let(:params) { super().merge(topic: 'Databases') }

      it 'lists only courses with that classifier' do
        request

        expect(page).to have_content 'A course with classifier'
        expect(page).to have_no_content 'Course 1'
        expect(page).to have_no_content 'Course 2'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
        expect(page).to have_no_content 'A course with channel'
      end

      context 'when the classifier belongs to an invisible cluster' do
        let(:cluster) { create(:cluster, :invisible, id: 'topic') }

        it 'lists only courses with that classifier' do
          request

          expect(page).to have_content 'A course with classifier'
          expect(page).to have_no_content 'Course 1'
          expect(page).to have_no_content 'Course 2'
          expect(page).to have_no_content 'Course 3'
          expect(page).to have_no_content 'Course 4'
          expect(page).to have_no_content 'A course with channel'
        end
      end
    end

    context 'when filtered by channel and classifier' do
      let(:params) { super().merge(channel: channel_course.channel.code, topic: 'Databases') }

      before { channel_course.classifiers << classifier }

      it 'lists only courses that fulfill both criteria' do
        request

        expect(page).to have_content 'A course with channel'
        expect(page).to have_no_content 'Course 1'
        expect(page).to have_no_content 'Course 2'
        expect(page).to have_no_content 'Course 3'
        expect(page).to have_no_content 'Course 4'
        expect(page).to have_no_content 'A course with classifier'
      end
    end

    context 'when filtered by language' do
      let(:params) { super().merge(lang: 'de') }

      it 'lists only matching courses' do
        request

        expect(page).to have_no_content 'Course 1'
        expect(page).to have_content 'Course 2' # MATCH!
        expect(page).to have_no_content 'Course 3' # Match, but deleted
        expect(page).to have_no_content 'Course 4'
        expect(page).to have_no_content 'A course with channel'
        expect(page).to have_no_content 'A course with classifier'
      end
    end
  end
end
