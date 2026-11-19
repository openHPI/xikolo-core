# frozen_string_literal: true

require 'spec_helper'

describe CourseService::CoursesController, type: :controller do
  include_context 'course_service API controller'
  let(:course) { create(:'course_service/course') }
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
        expect(json[0]).to eq CourseService::CourseDecorator.new(course, context: {collection: true}).as_json(api_version: 1).merge(teacher_text: '').except('description').stringify_keys
      end
    end

    describe 'order' do
      let(:action) { -> { get :index, params: } }

      context 'latest first' do
        let(:params) { {latest_first: 'true'} }
        let!(:records) { create_list(:'course_service/course', 5) }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(5).items }
          it { expect(json.pluck('id')).to match_array records.sort_by!(&:created_at).reverse!.pluck('id') }
        end
      end

      context 'alphabetic' do
        let(:params) { {alphabetic: 'true'} }

        before do
          create(:'course_service/course', course_code: 'course-c')
          create(:'course_service/course', course_code: 'kurs-d')
          create(:'course_service/course', course_code: 'course-e')
          create(:'course_service/course', course_code: 'kurs-b')
          create(:'course_service/course', course_code: 'course-a')
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

    describe 'filter' do
      let(:action) { -> { get :index, params: } }

      context 'by public' do
        let!(:active_courses) { create_list(:'course_service/course', 5) }
        let!(:archive_courses) { create_list(:'course_service/course', 7) }
        let(:params) { {public: 'true'} }

        describe 'json' do
          before do
            create_list(:'course_service/course', 6, published: false)
            action.call
          end

          it { expect(json).to have(active_courses.count + archive_courses.count).items }
        end
      end

      context 'by excluded external courses' do
        let!(:public_courses) { create_list(:'course_service/course', 7) }
        let(:params) { {exclude_external: 'true'} }

        before { create_list(:'course_service/course', 3, external_course_url: 'http://somwhere.com') }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(public_courses.count).items }
        end
      end

      context 'by included hidden courses' do
        let!(:hidden_courses) { create_list(:'course_service/course', 3, placement: []) }
        let!(:public_courses) { create_list(:'course_service/course', 7) }
        let(:params) { {} }

        describe 'json' do
          before { action.call }

          it { expect(json).to have(hidden_courses.count + public_courses.count).items }
        end
      end

      context 'by excluded hidden courses' do
        let(:hidden_courses) { create_list(:'course_service/course', 3, placement: []) }
        let!(:public_courses) { create_list(:'course_service/course', 7) }
        let(:params) { {placement: ['Open4All']} }

        describe 'json' do
          before do
            action.call
            hidden_courses
          end

          it { expect(json).to have(public_courses.count).items }
        end
      end

      context 'by active after' do
        let(:params) { {active_after: '2018-04-07'} }
        let!(:not_filtered_course) { create(:'course_service/course', start_date: 3.years.ago, end_date: 2.years.ago) }
        let!(:another_not_filtered_course) { create(:'course_service/course', start_date: 2.years.ago, end_date: 1.year.ago) }
        let!(:course_without_end_date) { create(:'course_service/course', end_date: nil) }

        before { create_list(:'course_service/course', 3, start_date: 5.years.ago, end_date: 4.years.ago) }

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
          create_list(:'course_service/course', 4)
          create_list(:'course_service/course', 2, groups: ['partners'])
          create_list(:'course_service/course', 1, groups: ['avengers'])
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
        expect(json).to eq CourseService::CourseDecorator.new(course).as_json(api_version: 1).merge(teacher_text: '').stringify_keys
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
    let(:params) { attributes_for(:'course_service/course') }
    let(:context_id) { AccountService::Context.root.id }

    before do
      create(:'course_service/cluster', id: 'category')
      create(:'course_service/cluster', id: 'topic')

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
      expect { action.call }.to change(CourseService::Course, :count).from(0).to(1)
    end

    it 'creates new course and classifier' do
      expect { action.call }.to(change(CourseService::Course, :count).from(0).to(1)) &&
        change(CourseService::Classifier, :count).from(0).to(1)
    end

    it 'responses with a 200' do
      action.call
      expect(response).to have_http_status :created
    end

    it 'assigns the context id' do
      action.call
      expect(CourseService::Course.first.context_id).to eq context_id
    end

    describe 'with learning_goals params present' do
      let(:params) { super().merge(learning_goals: %w[goal1 goal2]) }

      before { action.call }

      it 'includes learning_goals params' do
        expect(json).to include 'learning_goals'
      end

      it 'learning_goals persists value correctly' do
        expect(json['learning_goals']).to eq %w[goal1 goal2]
      end
    end

    context 'with access groups' do
      let(:params) { super().merge(groups: ['test.group'], published: false) }

      it 'stores the access groups' do
        action.call
        course = CourseService::Course.find(json['id'])
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
