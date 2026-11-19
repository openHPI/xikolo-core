# frozen_string_literal: true

require 'spec_helper'

describe 'Home: Courses: Index', type: :request do
  subject(:request) do
    get '/learn', headers:, params:
  end

  let(:headers) { {} }
  let(:page) { Capybara.string(response.body) }
  let(:params) { {} }
  let(:cluster) { create(:cluster, :visible, id: 'topic') }
  let(:classifier) { create(:classifier, cluster:, title: 'Databases') }

  let!(:hidden_course) do
    create(:course, title: 'Course 4', placement: [],
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
  end
  let!(:channel_course) do
    create(:course, :with_channel, title: 'A course with channel',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
  end

  before do
    create(:course, title: 'Course 1', abstract: 'Active course not in a channel',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, title: 'Course 2', published: true, lang: 'de',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, title: 'Course 3', deleted: 'true', lang: 'de',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    create(:course, title: 'A course with classifier',
      start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1)).tap do |c|
      c.classifiers << classifier
    end
  end

  shared_examples 'ajax request' do
    context 'as an ajax request' do
      let(:headers) { super().merge('X-Requested-With': 'XMLHttpRequest') }
      let(:params) { super().merge(page: 2) }

      # rubocop:disable-next FactoryBot/ExcessiveCreateList
      before do
        # On page 1 are 'Course 1', 'Course 2', 'A course with classifier', 'A course with channel', and:
        create_list(:course, 8, title: 'Self-paced course on page 1', published: true,
          start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))

        create_list(:course, 12, title: 'Self-paced course on page 2', published: true,
          start_date: DateTime.new(2016, 11, 1), end_date: DateTime.new(2016, 12, 1))
        create_list(:course, 12, title: 'Self-paced course on page 3', published: true,
          start_date: DateTime.new(2017, 11, 1), end_date: DateTime.new(2017, 12, 1))
      end

      it 'renders the courses partial for page 2 with 12 self-paced courses' do
        request
        expect(response.headers['X-Total-Pages']).to eq '3'
        expect(response.headers['X-Current-Page']).to eq '2'

        expect(response).to render_template partial: '_courses'

        expect(page).to have_text 'Self-paced course on page 2', count: 12

        expect(page).to have_no_text 'Self-paced course on page 1'
        expect(page).to have_no_text 'Self-paced course on page 3'
        expect(page).to have_no_text 'Course 1'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'A course with channel'
        expect(page).to have_no_text 'A course with classifier'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
      end
    end
  end

  context 'as anonymous user' do
    it_behaves_like 'ajax request'

    it 'lists all public courses' do
      request
      expect(response).to have_http_status :ok
      expect(response).to render_template :index

      expect(page).to have_text 'Course 1'
      expect(page).to have_text 'Course 2'
      expect(page).to have_text 'A course with channel'
      expect(page).to have_text 'A course with classifier'
      expect(page).to have_no_text 'Course 3'
      expect(page).to have_no_text 'Course 4'
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
        expect(page).to have_text 'Course 1'
        expect(page).to have_text 'Course 2'
        expect(page).to have_text 'A course with channel'
        expect(page).to have_text 'A course with classifier'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
      end
    end
  end

  context 'as logged in user' do
    let(:headers) { {} }
    let(:user) { create(:'account_service/user') }

    before { sign_in(user:) }

    it_behaves_like 'ajax request'

    it 'lists all public courses' do
      request
      expect(response).to have_http_status :ok
      expect(response).to render_template :index

      expect(page).to have_text 'Course 1'
      expect(page).to have_text 'Course 2'
      expect(page).to have_text 'A course with channel'
      expect(page).to have_text 'A course with classifier'
      expect(page).to have_no_text 'Course 3'
      expect(page).to have_no_text 'Course 4'
    end

    context 'when enrolled in a hidden course' do
      before do
        create(:enrollment, user_id: user.id, course_id: hidden_course.id)
      end

      it 'does not list that hidden course' do
        request

        expect(page).to have_text 'Course 1'
        expect(page).to have_text 'Course 2'
        expect(page).to have_text 'A course with channel'
        expect(page).to have_text 'A course with classifier'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
      end
    end

    context 'when filtered by text search query' do
      let(:params) { super().merge(q: 'channel') }

      it 'lists only courses matching that query (e.g. in title or abstract)' do
        skip 'Search reindexing of courses does not yet happen in xi-web'

        request

        expect(page).to have_text 'Course 1'
        expect(page).to have_text 'A course with channel'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with classifier'
      end
    end

    context 'when filtered by channel code' do
      let(:params) { super().merge(channel: channel_course.channels.first.code) }

      it 'lists only courses belonging to that channel' do
        request

        expect(page).to have_text 'A course with channel'
        expect(page).to have_no_text 'Course 1'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with classifier'
      end
    end

    context 'when filtered by classifier' do
      let(:params) { super().merge(topic: 'Databases') }

      it 'lists only courses with that classifier' do
        request

        expect(page).to have_text 'A course with classifier'
        expect(page).to have_no_text 'Course 1'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with channel'
      end

      context 'when the classifier belongs to an invisible cluster' do
        let(:cluster) { create(:cluster, :invisible, id: 'topic') }

        it 'lists only courses with that classifier' do
          request

          expect(page).to have_text 'A course with classifier'
          expect(page).to have_no_text 'Course 1'
          expect(page).to have_no_text 'Course 2'
          expect(page).to have_no_text 'Course 3'
          expect(page).to have_no_text 'Course 4'
          expect(page).to have_no_text 'A course with channel'
        end
      end
    end

    context 'when filtered by channel and classifier' do
      let(:params) { super().merge(channel: channel_course.channels.first.code, topic: 'Databases') }

      before { channel_course.classifiers << classifier }

      it 'lists only courses that fulfill both criteria' do
        request

        expect(page).to have_text 'A course with channel'
        expect(page).to have_no_text 'Course 1'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with classifier'
      end
    end

    context 'when filtered by language' do
      let(:params) { super().merge(lang: 'de') }

      it 'lists only matching courses' do
        request

        expect(page).to have_no_text 'Course 1'
        expect(page).to have_text 'Course 2' # MATCH!
        expect(page).to have_no_text 'Course 3' # Match, but deleted
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with channel'
        expect(page).to have_no_text 'A course with classifier'
      end
    end

    context 'when filtered by format' do
      let(:params) { super().merge(course_format: 'workshop') }

      before do
        create(:course, title: 'A Workshop', course_format: 'workshop')
      end

      it 'lists only matching courses' do
        request

        expect(page).to have_text 'A Workshop'
        expect(page).to have_no_text 'Course 1'
        expect(page).to have_no_text 'Course 2'
        expect(page).to have_no_text 'Course 3'
        expect(page).to have_no_text 'Course 4'
        expect(page).to have_no_text 'A course with channel'
        expect(page).to have_no_text 'A course with classifier'
      end

      it 'only lists formats with at least one learning unit' do
        request

        # 'course' and 'workshop' learning units exist, but no 'project' unit.
        expect(page).to have_select 'Format', options: %w[All Course Workshop]
      end
    end

    context 'when only one format has learning units' do
      it 'does not show the format filter' do
        request

        # All learning units created by default use the 'course' format.
        expect(page).to have_no_select 'Format'
      end
    end

    context 'when filtered by an invalid format' do
      let(:params) { super().merge(course_format: 'garbage') }

      it 'ignores values not matching the course_format enum' do
        request

        expect(response).to have_http_status :ok
        expect(page).to have_text 'Course 1'
      end
    end
  end
end
