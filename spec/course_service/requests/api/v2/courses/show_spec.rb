# frozen_string_literal: true

require 'spec_helper'

describe '[API v2] Course: Show', type: :request do
  subject(:resource) { api.rel(:course).get(params).value! }

  before do
    Stub.service(:account, build(:'account:root'))
  end

  let(:api) { restify_with_headers(course_service.api_v2_course_root_url, headers: session_headers).get.value }
  let(:session_headers) { session_request_headers session }

  let(:session) do
    Stub.request(
      :account, :get,
      "/sessions/anonymous?context=#{course.context_id}&embed=user,permissions,features"
    ).to_return Stub.json({
      id: nil,
      user_id: nil,
      masqueraded: false,
      features: [],
      permissions:,
    })

    if user_id
      session_id = generate_session_id
      Stub.request(
        :account, :get,
        "/sessions/#{session_id}?context=#{course.context_id}&embed=user,permissions,features"
      ).to_return Stub.json({
        id: session_id,
        user_id:,
        user: user.merge(id: user_id, anonymous: false),
        masqueraded: false,
        features: [],
        permissions:,
      })
      session_id
    end
  end
  let(:user) { {} }
  let(:user_id) { generate(:user_id) }
  let(:permissions) { ['course.course.show'] }
  let(:params) { {id: course.id} }

  let!(:course) { create(:'course_service/course', course_attrs) }
  let(:course_attrs) { {} }
  let(:course_full) { CourseService::Course.where(id: course.id).from('embed_courses AS courses').take! }

  shared_examples 'show course never' do |_section|
    it 'does not show courses (when no enrollment)' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end

    it 'does not show course (when enrollment)' do
      create(:'course_service/enrollment', user_id:, course_id: course.id)
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  shared_examples 'a basic API v2 course' do
    its(['id']) { is_expected.to eq course.id }
    its(['course_code']) { is_expected.to eq course.course_code }
    its(['title']) { is_expected.to eq course.title }
    its(['abstract']) { is_expected.to eq course.abstract }

    it 'has an empty teachers without teachers or alternative teacher text' do
      expect(resource['teachers']).to eq ''
    end

    context 'with teachers' do
      let!(:teachers) { create_list(:'course_service/teacher', 2) }
      let(:course_attrs) { super().merge teacher_ids: teachers.map(&:id) }

      context 'but alternative teacher text' do
        it 'uses alternative teacher text if present' do
          expect(resource['teachers']).to eq "#{teachers[0].name}, #{teachers[1].name}"
        end
      end

      context 'and alternative teacher text' do
        let(:course_attrs) { super().merge alternative_teacher_text: 'Your teachers! Yeah!' }

        it 'uses alternative teacher text if present' do
          expect(resource['teachers']).to eq 'Your teachers! Yeah!'
        end
      end
    end

    its(['language']) { is_expected.to eq 'se' }

    context 'without channel' do
      its(['channel_code']) { is_expected.to be_nil } # we have no channel at the moment
    end

    context 'with channel' do
      let(:channel) { create(:'course_service/channel', code: 'important-group') }
      let(:course_attrs) { super().merge channel: }

      its(['channel_code']) { is_expected.to eq 'important-group' }
    end

    # classifiers: classifiers,
    # hidden: object.hidden,
    # invite_only: object.invite_only,

    context 'for a announced course' do
      let(:course_attrs) { super().merge start_date: 2.days.from_now, end_date: 3.days.from_now }

      its(['state']) { is_expected.to eq 'announced' }
    end

    context 'for a preview course' do
      let(:course_attrs) { super().merge start_date: 2.days.ago, display_start_date: 2.days.from_now, end_date: 3.weeks.from_now }

      its(['state']) { is_expected.to eq 'preview' }
    end

    context 'for a active course' do
      let(:course_attrs) { super().merge start_date: 2.days.ago, display_start_date: 2.days.ago, end_date: 3.weeks.from_now }

      its(['state']) { is_expected.to eq 'active' }
    end

    context 'for a self-paced course' do
      let(:course_attrs) { super().merge start_date: 2.days.ago, display_start_date: 2.days.ago, end_date: 1.day.ago }

      its(['state']) { is_expected.to eq 'self-paced' }
    end

    context 'without start date' do
      let(:course_attrs) { super().merge start_date: nil, display_start_date: nil }

      its(['start_date']) { is_expected.to be_nil }
    end

    context 'without display_start_date but start_date' do
      let(:course_attrs) { super().merge display_start_date: nil }

      its(['start_date']) { is_expected.to eq course.start_date.iso8601 }
    end

    context 'with display_start_date' do
      let(:course_attrs) { super().merge display_start_date: 2.days.ago }

      its(['start_date']) { is_expected.to eq course.display_start_date.iso8601 }
    end

    context 'without end date' do
      let(:course_attrs) { super().merge end_date: nil }

      its(['end_date']) { is_expected.to be_nil }
    end

    context 'with end date' do
      let(:course_attrs) { super().merge end_date: 3.days.from_now }

      its(['end_date']) { is_expected.to eq course.end_date.iso8601 }
    end
  end

  context 'as anonymous user' do
    let(:user_id) { nil }
    let(:permissions) { ['course.course.show'] }

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true, status: 'active'} }

      it 'does not see it' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end

    context 'without course show permission' do
      let(:course_attrs) { {groups: ['partners'], status: 'active'} }
      let(:permissions) { [] }

      it 'does not see it' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :unauthorized
        end
      end
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it 'sees it' do
        expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { {status: 'preparation'} }

      it 'does not see it' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end
  end

  context 'as student' do
    let(:permissions) { ['course.course.show'] }

    context 'with group restricted course' do
      let(:course_attrs) { {groups: ['partners'], status: 'active'} }

      context 'without course show permission' do
        let(:permissions) { [] }

        it 'does not see it' do
          expect { resource }.to raise_error(Restify::ClientError) do |error|
            expect(error.status).to eq :unauthorized
          end
        end
      end

      context 'with course show permission' do
        let(:permissions) { ['course.course.show'] }

        it 'sees it' do
          expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
        end
      end
    end

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true, status: 'active'} }

      it_behaves_like 'show course never'
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it 'sees it' do
        expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { {status: 'preparation'} }

      it_behaves_like 'show course never'
    end
  end

  context 'as admin user' do
    let(:permissions) { %w[course.content.access course.course.show] }
    let(:user) { {admin: true} }

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true, status: 'active'} }

      it 'does not see deleted courses' do
        expect { resource }.to raise_error(Restify::ClientError) do |error|
          expect(error.status).to eq :not_found
        end
      end
    end

    context 'with group restricted course' do
      let(:course_attrs) { {groups: ['partners'], status: 'active'} }

      it 'sees restricted course' do
        expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
      end
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it 'sees hidden courses' do
        expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
      end
    end

    context 'with preparation course' do
      let(:course_attrs) { {status: 'preparation'} }

      it 'sees hidden courses' do
        expect(resource).to eq json(course_full.decorate.as_json(api_version: 2))
        expect(resource['state']).to eq 'preparation'
      end
    end
  end

  context 'one course entry' do
    let(:course_attrs) do
      {
        status: 'active',
        description: 'Course Characteristics --------------- ...',
        display_start_date: 2.days.ago,
        end_date: 2.days.from_now,
        lang: 'se',
      }
    end

    it 'finds course by id' do
      request = api.rel(:course).get({id: course.id}).value!
      expect(request.response.status).to eq :ok
    end

    it 'finds course by short UUID' do
      request = api.rel(:course).get({id: UUID4(course.id).to_str(format: :base62)}).value!
      expect(request.response.status).to eq :ok
    end

    it 'finds course by course_code' do
      request = api.rel(:course).get({id: course.course_code}).value!
      expect(request.response.status).to eq :ok
    end

    context 'with course code that can be interpreted as short UUID' do
      let(:course_attrs) { super().merge(course_code: 'javaeinstieg2015') }

      it 'finds course by course_code' do
        request = api.rel(:course).get({id: course.course_code}).value!
        expect(request.response.status).to eq :ok
      end
    end

    context 'with enrollment' do
      let!(:enrollment) { create(:'course_service/enrollment', user_id:, course_id: course.id) }

      it_behaves_like 'a basic API v2 course'

      it 'does not include description by default' do
        expect(resource.keys).not_to include 'description'
      end

      context 'if description is wanted' do
        let(:params) { super().merge(embed: 'description') }

        it { is_expected.to have_key 'description' }

        it 'includes description' do
          expect(resource['description']).to eq 'Course Characteristics --------------- ...'
        end

        context 'with inlined descriptions' do
          let(:course_attrs) do
            super().merge description: 'Headline\n--\n s3://xikolo-public/courses/34/rtfiles/3/hans.jpg'
          end

          it 'returns it with external URLs' do
            expect(resource['description']).to eq 'Headline\n--\n https://s3.xikolo.de/xikolo-public/courses/34/rtfiles/3/hans.jpg'
          end
        end
      end

      it 'does not include enrollment data by default' do
        expect(resource.keys).not_to include 'enrollment'
      end

      context 'and requested enrollment info' do
        let(:params) { super().merge embed: 'enrollment' }

        it_behaves_like 'a basic API v2 course'

        its(['enrollment'], skip: 'This feature seems unused in open.hpi. Making this test work in a web test setup is difficult. Test skipped, but feature is working.') do
          is_expected.to eq(
            'id' => enrollment.id,
            'user_id' => enrollment.user_id,
            'completed' => false,
            'confirmed' => true,
            'points' => {
              'achieved' => 0.0,
              'maximal' => 0.0,
              'percentage' => 0.0,
            },
            'visits' => {
              'visited' => 0,
              'total' => 0,
              'percentage' => 0.0,
            },
            'certificates' => {
              'confirmation_of_participation' => false,
              'record_of_achievement' => false,
              'certificate' => false,
            },
            'reactivated' => false
          )
        end
      end
    end

    context 'without enrollment' do
      it_behaves_like 'a basic API v2 course'

      it 'does not include enrollment info' do
        expect(resource.keys).not_to include 'enrollment'
      end

      it 'does not include description by default' do
        expect(resource.keys).not_to include 'description'
      end

      context 'if description is wanted' do
        let(:params) { super().merge(embed: 'description') }

        it { is_expected.to have_key 'description' }

        it 'includes description' do
          expect(resource['description']).to eq 'Course Characteristics --------------- ...'
        end

        context 'with descriptions with files' do
          let(:course_attrs) do
            super().merge description: 'Headline\n--\n s3://xikolo-public/courses/34/rtfiles/3/hans.jpg'
          end

          it 'returns it with external URLs' do
            expect(resource['description']).to eq 'Headline\n--\n https://s3.xikolo.de/xikolo-public/courses/34/rtfiles/3/hans.jpg'
          end
        end
      end

      context 'and requested enrollment info' do
        let(:params) { super().merge embed: 'enrollment' }

        it_behaves_like 'a basic API v2 course'

        its(['enrollment']) { is_expected.to be_nil }
      end

      context 'for a external course' do
        let(:course_attrs) { super().merge external_course_url: 'https://example.org/test' }

        its(['state']) { is_expected.to eq 'external' }
        its(['external_course_url']) { is_expected.to eq 'https://example.org/test' }
      end
    end
  end

  context 'with missing session' do
    let(:session) do
      Stub.request(
        :account, :get,
        "/sessions/anonymous?context=#{course.context_id}&embed=user,permissions,features"
      ).to_return status: 404
    end

    it 'respond with Unauthorized' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unauthorized
      end
    end
  end
end
