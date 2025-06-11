# frozen_string_literal: true

require 'spec_helper'

describe CoursesController, type: :controller do
  let(:course) { create(:course) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe "GET 'index'" do
    let(:request) { -> { get :index } }

    context 'response' do
      before { request.call }

      it { expect(response).to have_http_status :ok }
    end

    context 'json' do
      before do
        course
        request.call
      end

      it { expect(json).to have(1).item }

      it 'contains a course resource' do
        expect(json[0]).to eq CourseDecorator.new(course, context: {collection: true}).as_json(api_version: 1).merge(teacher_text: '').except('description').stringify_keys
      end
    end

    describe 'order' do
      let(:action) { -> { get :index, params: } }

      context 'latest first' do
        let(:params) { {latest_first: 'true'} }
        let!(:records) { create_list(:course, 5, status: 'active') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(5).items }
          it { expect(json.pluck('id')).to match_array records.sort_by!(&:created_at).reverse!.pluck('id') }
        end
      end

      context 'alphabetic' do
        let(:params) { {alphabetic: 'true'} }

        before do
          create(:course, course_code: 'course-c')
          create(:course, course_code: 'kurs-d')
          create(:course, course_code: 'course-e')
          create(:course, course_code: 'kurs-b')
          create(:course, course_code: 'course-a')
        end

        describe 'json' do
          before { action.call }

          it 'sorts the courses by course code' do
            expect(json).to match [
              hash_including('course_code' => 'course-a'),
              hash_including('course_code' => 'course-c'),
              hash_including('course_code' => 'course-e'),
              hash_including('course_code' => 'kurs-b'),
              hash_including('course_code' => 'kurs-d'),
            ]
          end
        end
      end
    end

    describe 'sorting' do
      let(:action) { -> { get :index, params: } }

      before do
        Timecop.freeze
        create(:course, display_start_date: Time.current, start_date: 2.days.ago, title: 'A')
        create(:course, display_start_date: nil, start_date: 1.day.ago, title: 'B')
        create(:course, display_start_date: 2.days.ago, start_date: 2.days.ago, title: 'D')
        create(:course, display_start_date: nil, start_date: 2.days.ago, title: 'C')
      end

      context 'started recently first' do
        let(:params) { {sort: 'started_recently_first'} }

        describe 'json' do
          before { action.call }

          it 'sorts the courses' do
            expect(json).to match [
              hash_including('title' => 'A'),
              hash_including('title' => 'B'),
              hash_including('title' => 'C'),
              hash_including('title' => 'D'),
            ]
          end
        end
      end

      context 'started earliest first' do
        let(:params) { {sort: 'started_earliest_first'} }

        describe 'json' do
          before { action.call }

          it 'sorts the courses' do
            expect(json).to match [
              hash_including('title' => 'C'),
              hash_including('title' => 'D'),
              hash_including('title' => 'B'),
              hash_including('title' => 'A'),
            ]
          end
        end
      end
    end

    describe 'filter' do
      let(:action) { -> { get :index, params: } }

      context 'by classifier' do
        let(:classifier) { create(:classifier) }
        let!(:records) { create_list(:course, 5, classifiers: classifier) }
        let(:params) { {cat_id: classifier.id} }

        before { create_list(:course, 10) }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(5).items }
          it { expect(json.pluck('id')).to match_array records.map(&:id) }
        end
      end

      context 'by channel' do
        let(:channel_a) { create(:channel, code: 'a') }
        let(:channel_b) { create(:channel, code: 'b') }
        let!(:channel_courses) { create_list(:course, 7, channel_id: channel_a.id) }
        let(:params) { {channel_id: channel_a} }

        before do
          create_list(:course, 3, channel_id: nil)
          create_list(:course, 1, channel_id: channel_b.id)
        end

        describe 'json' do
          before { action.call }

          it { expect(json).to have(channel_courses.count).items }
          it { expect(json.pluck('id')).to match_array channel_courses.map(&:id) }
        end
      end

      context 'by document' do
        let!(:document1) { create(:document) }
        let!(:document2) { create(:document) }
        let!(:course_a) { create(:course) }
        let!(:course_b) { create(:course) }
        let!(:course_c) { create(:course) }
        let(:params) { {document_id: document1.id} }

        before do
          document1.courses << course_a << course_b
          document2.courses << course_c
        end

        it 'shows only the documents of Course A' do
          action.call
          expect(json.pluck('id')).to contain_exactly(course_a.id, course_b.id)
        end
      end

      context 'by status' do
        let!(:records) { create_list(:course, 3) }
        let(:params) { {status: 'preparation'} }

        before { create_list(:course, 5, status: 'active') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(3).items }
          it { expect(json.pluck('id')).to match_array records.map(&:id) }
        end
      end

      context 'by upcoming' do
        let(:params) { {upcoming: 'true'} }

        before do
          create_list(:course, 5, status: 'active', start_date: 2.days.ago, end_date: 30.days.from_now)
          create(:course, course_code: 'course-a', status: 'active', start_date: 1.week.from_now, end_date: 30.days.from_now)
          create(:course, course_code: 'course-b', status: 'active', start_date: 2.days.from_now, end_date: 30.days.from_now)
        end

        describe 'json' do
          before { action.call }

          it { expect(json).to have(2).items }

          it 'sorts the courses by earliest start date' do
            expect(json).to match [
              hash_including('course_code' => 'course-b'),
              hash_including('course_code' => 'course-a'),
            ]
          end
        end
      end

      context 'by upcoming with display_date' do
        let(:params) { {upcoming: 'true'} }

        before do
          create_list(:course, 5, status: 'active', end_date: 30.days.from_now)

          two_weeks_from_now = 2.weeks.from_now
          create(:course, course_code: 'course-a', status: 'active', start_date: 4.days.from_now, display_start_date: two_weeks_from_now, end_date: 20.days.from_now)
          create(:course, course_code: 'course-b', status: 'active', start_date: 3.days.from_now, display_start_date: two_weeks_from_now, end_date: 20.days.from_now)
          create(:course, course_code: 'course-c', status: 'active', start_date: 1.week.from_now, end_date: 20.days.from_now)
        end

        describe 'json' do
          before { action.call }

          it { expect(json).to have(3).items }

          it 'sorts the courses by earliest start date and display start date' do
            expect(json).to match [
              hash_including('course_code' => 'course-c'),
              hash_including('course_code' => 'course-a'),
              # The start_date is ignored if the display_start_date is the same.
              hash_including('course_code' => 'course-b'),
            ]
          end
        end
      end

      context 'by public' do
        let!(:active_courses) { create_list(:course, 5, status: 'active') }
        let!(:archive_courses) { create_list(:course, 7, status: 'archive') }
        let(:params) { {public: 'true'} }

        describe 'json' do
          before do
            create_list(:course, 6, status: 'preparation')
            action.call
          end

          it { expect(json).to have(active_courses.count + archive_courses.count).items }
        end
      end

      context 'by excluded external courses' do
        let!(:public_courses) { create_list(:course, 7) }
        let(:params) { {exclude_external: 'true'} }

        before { create_list(:course, 3, external_course_url: 'http://somwhere.com') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(public_courses.count).items }
        end
      end

      context 'by excluded hidden courses' do
        let!(:public_courses) { create_list(:course, 7, hidden: 'false') }
        let(:params) { {hidden: 'false'} }

        before { create_list(:course, 3, hidden: 'true') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(public_courses.count).items }
        end
      end

      context 'by included hidden courses' do
        let!(:hidden_courses) { create_list(:course, 3, hidden: 'true') }
        let!(:public_courses) { create_list(:course, 7, hidden: 'false') }
        let(:params) { {} }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(hidden_courses.count + public_courses.count).items }
        end
      end

      context 'by only hidden' do
        let!(:hidden_courses) { create_list(:course, 3, hidden: 'true') }
        let(:params) { {only_hidden: 'true'} }

        before { create_list(:course, 7, hidden: 'false') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(hidden_courses.count).items }
        end
      end

      context 'by active after' do
        let(:params) { {active_after: '2018-04-07'} }
        let!(:not_filtered_course) { create(:course, start_date: 3.years.ago, end_date: 2.years.ago) }
        let!(:another_not_filtered_course) { create(:course, start_date: 2.years.ago, end_date: 1.year.ago) }
        let!(:course_without_end_date) { create(:course, end_date: nil) }

        before { create_list(:course, 3, start_date: 5.years.ago, end_date: 4.years.ago) }

        around do |example|
          date = Date.new(2021, 4, 7)
          Timecop.freeze(date) { example.run }
        end

        describe 'json' do
          before { action.call }

          it 'returns only courses with no end date or with end date newer than 3 years' do
            expect(json).to contain_exactly(hash_including('id' => not_filtered_course.id), hash_including('id' => another_not_filtered_course.id), hash_including('id' => course_without_end_date.id))
          end
        end
      end

      context 'by groups' do
        before do
          create_list(:course, 4)
          create_list(:course, 2, groups: ['partners'])
          create_list(:course, 1, groups: ['avengers'])
          action.call
        end

        context 'with any groups' do
          let(:params) { {groups: 'any'} }

          it { expect(json).to have(7).items }
        end

        context 'with specific groups' do
          let(:params) { {groups: 'partners'} }

          it { expect(response).to have_http_status :bad_request }
        end
      end

      context 'promotion for user' do
        subject(:response_body) { action.call; json }

        let(:user_id) { generate(:user_id) }
        let(:params) { {promoted_for: user_id} }

        let!(:course) { create(:course, course_params) }
        let(:course_params) { {start_date: DateTime.now + 3.days, end_date: DateTime.now + 7.days, status: 'active'} }

        before do
          Stub.request(:account, :get, '/groups', query: {
            user: user_id,
            per_page: 1000,
          }).to_timeout
        end

        context 'should not return ended courses' do
          let(:course_params) { super().merge start_date: 6.days.ago, end_date: 3.days.ago }

          its(:size) { is_expected.to eq 0 }
        end

        context 'should return courses without end date' do
          let(:course_params) { super().merge end_date: nil }

          its(:size) { is_expected.to eq 1 }
        end

        context 'should not return courses in preparation' do
          let(:course_params) { super().merge status: 'preparation' }

          its(:size) { is_expected.to eq 0 }
        end

        context 'should not return archived courses' do
          let(:course_params) { super().merge status: 'archive' }

          its(:size) { is_expected.to eq 0 }
        end

        context 'should exclude hidden courses' do
          let(:course_params) { super().merge hidden: true }

          its(:size) { is_expected.to eq 0 }
        end

        context 'should exclude enrolled courses' do
          before { create(:enrollment, course:, user_id:) }

          its(:size) { is_expected.to eq 0 }
        end

        context 'should return not started courses' do
          its(:size) { is_expected.to eq 1 }
        end

        context 'should return not ended courses' do
          let(:course_params) { super().merge start_date: 1.day.ago }

          its(:size) { is_expected.to eq 1 }
        end

        context 'with group restrictions' do
          before do
            Stub.request(:account, :get, '/groups', query: {
              user: user_id,
              per_page: 1000,
            }).to_return Stub.json([{name: 'user.group'}])
          end

          it 'does not list inaccessible courses' do
            course.update! groups: ['another.group']
            expect(response_body.size).to be_zero
          end

          it 'does list user accessible courses' do
            course.update! groups: ['user.group']
            expect(response_body.size).to eq 1
          end
        end

        context 'ordering' do
          let!(:second_course) do
            create(:course, status: 'active',
              start_date: second_start_date,
              display_start_date: second_display_date,
              end_date: DateTime.now + 5.days)
          end
          let(:second_start_date) { nil }
          let(:second_display_date) { nil }

          context 'only with start dates' do
            let(:second_start_date) { DateTime.now + 1.day }

            its(:size) { is_expected.to eq 2 }

            it 'is ordered by display start date' do
              expect(response_body[0]['id']).to eq second_course.id
              expect(response_body[1]['id']).to eq course.id
              expect(response_body[0]['display_start_date']).to be < response_body[1]['display_start_date']
            end
          end

          context 'with display start but not start dates' do
            let(:second_display_date) { DateTime.now + 1.day }

            its(:size) { is_expected.to eq 2 }

            it 'is ordered by display start date' do
              expect(response_body[0]['id']).to eq second_course.id
              expect(response_body[1]['id']).to eq course.id
              expect(response_body[0]['display_start_date']).to be < response_body[1]['display_start_date']
            end
          end

          context 'with display start and start dates' do
            let(:second_display_date) { DateTime.now + 4.days }
            let(:second_start_date) { DateTime.now + 1.day }

            its(:size) { is_expected.to eq 2 }

            it 'is ordered by display start date' do
              expect(response_body[0]['id']).to eq course.id
              expect(response_body[1]['id']).to eq second_course.id
              expect(response_body[0]['display_start_date']).to be < response_body[1]['display_start_date']
            end
          end

          context 'with display start and start dates (2)' do
            let(:course_params) { super().merge start_date: 1.day.from_now, display_start_date: 3.days.from_now }
            let(:second_display_date) { DateTime.now + 2.days }
            let(:second_start_date) { DateTime.now + 1.hour }

            its(:size) { is_expected.to eq 2 }

            it 'is ordered by display start date' do
              expect(response_body[0]['id']).to eq second_course.id
              expect(response_body[1]['id']).to eq course.id
              expect(response_body[0]['display_start_date']).to be < response_body[1]['display_start_date']
            end
          end
        end
      end

      context 'invalid filters' do
        subject { response.status }

        before { action.call }

        context 'my_courses' do
          let(:params) { {my_courses: true} }

          it { is_expected.to eq 400 }
        end

        context 'my_upcoming' do
          let(:params) { {my_upcoming: true} }

          it { is_expected.to eq 400 }
        end
      end
    end
  end

  describe "GET 'show'" do
    let(:request) { -> { get :show, params: {id: course.id} } }

    before do
      stub_request(:get, %r{\Ahttp://richtext.xikolo.tld/rich_texts/[-0-9a-f]+\z})
        .and_return(Stub.json({markup: 'Empty'}))
    end

    context 'response' do
      before { request.call }

      it { expect(response).to have_http_status :ok }
    end

    context 'json' do
      before { request.call }

      it 'contains a course resource' do
        expect(json).to eq CourseDecorator.new(course).as_json(api_version: 1).merge(teacher_text: '').stringify_keys
      end
    end

    context 'with course code' do
      let(:request) { -> { get :show, params: {id: course.course_code} } }

      before { request.call }

      it { expect(response).to have_http_status :ok }
    end

    context 'with unknown course code' do
      let(:request) { -> { get :show, params: {id: 'not-existing'} } }

      before { request.call }

      it { expect(response).to have_http_status :not_found }
    end

    context 'with deleted course' do
      before do
        course.update!(deleted: true)
        request.call
      end

      it { expect(response).to have_http_status :not_found }
    end
  end

  describe "POST 'create'" do
    let(:action) { -> { post :create, params: } }
    let(:params) { attributes_for(:course) }
    let(:context_id) { generate(:context_id) }

    before do
      create(:cluster, id: 'category')
      create(:cluster, id: 'topic')

      Stub.service(:account,
        contexts_url: '/contexts',
        group_url: '/groups/{id}',
        groups_url: '/groups')

      stub_request(:get, %r{\Ahttp://richtext.xikolo.tld/rich_texts/[-0-9a-f]+\z})
        .and_return(Stub.json({markup: 'Empty'}))

      Stub.request(:account, :post, '/contexts',
        body: {
          parent: 'root',
          reference_uri: "urn:x-xikolo:course:course:#{params[:course_code]}",
        }).to_return Stub.json({id: context_id})

      Stub.request(:account, :post, '/groups',
        body: {
          name: "course.#{params[:course_code]}.students",
          description: "Students of course #{params[:course_code]}",
        }).to_return Stub.json({name: "course.#{params[:course_code]}.students"})

      Xikolo.config.course_groups = {
        'students' => {
          'description' => 'Students of course %s',
          'grants' => [],
        },
      }
    end

    it 'creates new course' do
      expect { action.call }.to change(Course, :count).from(0).to(1)
    end

    it 'creates new course and classifier' do
      expect { action.call }.to(change(Course, :count).from(0).to(1)) &&
        change(Classifier, :count).from(0).to(1)
    end

    it 'responses with a 200' do
      action.call
      expect(response).to have_http_status :created
    end

    it 'assigns the context id' do
      action.call
      expect(Course.first.context_id).to eq context_id
    end

    describe 'with learning_goals and target_groups params present' do
      let(:params) { super().merge(learning_goals: %w[goal1 goal2], target_groups: %w[students professionals]) }

      before { action.call }

      it 'includes learning_goals and target_group params' do
        expect(json).to include 'learning_goals'
        expect(json).to include 'target_groups'
      end

      it 'target_groups persists value correctly' do
        expect(json['target_groups']).to eq %w[students professionals]
      end

      it 'learning_goals persists value correctly' do
        expect(json['learning_goals']).to eq %w[goal1 goal2]
      end
    end

    context 'with access groups' do
      let(:params) { super().merge(groups: ['test.group']) }

      it 'stores the access groups' do
        action.call
        course = Course.find(json['id'])
        expect(course.groups).to eq(['test.group'])
      end
    end

    context 'with invalid data' do
      let(:params) { {name: 'test'} }

      it 'responses with 422 on invalid data' do
        action.call
        expect(response).to have_http_status :unprocessable_content
      end
    end

    context 'with http errors' do
      before do
        Stub.request(:account, :post, '/contexts',
          body: {
            parent: 'root',
            reference_uri: "urn:x-xikolo:course:course:#{params[:course_code]}",
          }).to_return Stub.response(status: 422)
      end

      it 'returns a invalid course' do
        action.call
        expect(response).to have_http_status :unprocessable_content
      end
    end
  end
end
