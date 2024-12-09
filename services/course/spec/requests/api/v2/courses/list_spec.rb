# frozen_string_literal: true

require 'spec_helper'

describe '[API v2] Course: List', type: :request do
  subject(:request) { api.rel(:courses).get.value }

  let(:api) { Restify.new(:api, headers: session_headers).get.value }
  let(:session_headers) { session_request_headers session }
  let(:user_groups) { [] }
  let(:session) { setup_session user_id, permissions:, features: [], user: }
  let(:user_id) { generate(:user_id) }
  let(:user) { {} }
  let(:permissions) { [] }
  let!(:course) { create(:course, course_attrs) }
  let(:course_attrs) { {} }
  let(:course_full) { Course.where(id: course.id).from('embed_courses AS courses').take! }

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}',
      group_url: '/groups/{id}',
      groups_url: '/groups'
    )

    Stub.request(
      :account,
      :get,
      '/groups',
      query: {user: user_id, per_page: 1000}
    ).to_return Stub.json(user_groups)

    Stub.request(
      :account,
      :get,
      '/groups',
      query: {user: 'anonymous', per_page: 1000}
    ).to_return Stub.json([])
  end

  shared_examples 'list course only with enrollment' do
    it 'does not list courses (when no enrollment)' do
      expect(request).to eq json([])
    end

    it 'lists course (when enrollment)' do
      create(:enrollment, user_id:, course_id: course.id)
      expect(request).to eq json([course_full.decorate.as_json(api_version: 2)])
      expect(request[0]['id']).to eq course_full.id
    end
  end

  shared_examples 'list course never' do
    it 'does not list course (when no enrollment)' do
      expect(request).to eq json([])
    end

    it 'does not list course (when enrollment)' do
      create(:enrollment, user_id:, course_id: course.id)
      expect(request).to eq json([])
    end
  end

  shared_examples 'list course always' do
    it 'lists course (when no enrollment)' do
      expect(request).to eq json([course_full.decorate.as_json(api_version: 2)])
      expect(request[0]['id']).to eq course_full.id
    end

    it 'lists course (when enrollment)' do
      create(:enrollment, user_id:, course_id: course.id)
      expect(request).to eq json([course_full.decorate.as_json(api_version: 2)])
      expect(request[0]['id']).to eq course_full.id
    end
  end

  context 'as anonymous user' do
    let(:user_id) { nil }
    let(:permissions) { [] }

    it 'responds with 200 Ok' do
      expect(request.response.status).to eq :ok
    end

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true, status: 'active'} }

      it 'does not see it' do
        expect(request).to eq json([])
      end
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it 'does not see it' do
        expect(request).to eq json([])
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { {status: 'preparation'} }

      it 'does not see it' do
        expect(request).to eq json([])
      end
    end

    context 'with group restricted course' do
      let(:course_attrs) { {groups: ['partners']} }

      it 'does not see it' do
        expect(request).to eq json([])
      end
    end
  end

  context 'as student' do
    let(:permissions) { [] }

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true, status: 'active'} }

      it 'does not list courses (when no enrollment)' do
        expect(request).to eq json([])
      end
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it_behaves_like 'list course only with enrollment'
    end

    context 'with group restricted course' do
      let(:course_attrs) { {groups: ['partners'], status: 'active'} }

      context 'as non-partner user' do
        it_behaves_like 'list course only with enrollment'
      end

      context 'as partner user' do
        let(:user_groups) do
          [
            {name: 'partners'},
          ]
        end

        it_behaves_like 'list course always'
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { {status: 'preparation'} }

      it_behaves_like 'list course only with enrollment'
    end
  end

  context 'as admin user' do
    let(:permissions) { ['course.course.index'] }
    let(:user) { {admin: true} }

    it 'responds with 200 Ok' do
      expect(request.response.status).to eq :ok
    end

    context 'with deleted course' do
      let(:course_attrs) { {deleted: true} }

      it 'does not see deleted courses' do
        expect(request).to eq json([])
      end
    end

    context 'with hidden course' do
      let(:course_attrs) { {hidden: true, status: 'active'} }

      it 'does not see hidden courses' do
        expect(request).to eq json([])
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { {status: 'preparation'} }

      it 'does not see course' do
        expect(request).to eq json([])
      end
    end

    context 'with group restricted course' do
      let(:course_attrs) { {groups: ['partners'], status: 'active'} }

      it 'does not see restricted course' do
        expect(request).to eq json([])
      end
    end
  end

  describe 'channel filter' do
    subject(:request) { api.rel(:courses).get(params).value }

    let!(:channel_course) { create(:course, :with_channel, status: 'active') }
    let(:channel_course_full) { Course.where(id: channel_course.id).from('embed_courses AS courses').take! }

    context 'as student' do
      let(:permissions) { [] }

      context 'set to channel ID' do
        let(:params) { {channel: channel_course.channel.id} }

        it 'lists the course' do
          expect(request).to eq json([channel_course_full.decorate.as_json(api_version: 2)])
        end
      end

      context 'set to channel slug' do
        let(:params) { {channel: channel_course.channel.code} }

        it 'lists the course' do
          expect(request).to eq json([channel_course_full.decorate.as_json(api_version: 2)])
        end
      end

      context 'set to a non-existent slug' do
        let(:params) { {channel: '123'} }

        it 'does not list the course' do
          expect(request).to eq json([])
        end
      end
    end

    context 'as anonymous user' do
      let(:user_id) { nil }
      let(:permissions) { [] }

      context 'set to channel ID' do
        let(:params) { {channel: channel_course.channel.id} }

        it 'lists the course' do
          expect(request).to eq json([channel_course_full.decorate.as_json(api_version: 2)])
        end
      end

      context 'set to channel slug' do
        let(:params) { {channel: channel_course.channel.code} }

        it 'lists the course' do
          expect(request).to eq json([channel_course_full.decorate.as_json(api_version: 2)])
        end
      end

      context 'set to a non-existent slug' do
        let(:params) { {channel: '123'} }

        it 'does not list the course' do
          expect(request).to eq json([])
        end
      end
    end
  end

  context 'one course entry' do
    subject(:request) { api.rel(:courses).get.value[0] }

    let(:course_attrs) do
      {
        status: 'active',
        description: 'Course Characteristics --------------- ...',
        display_start_date: 2.days.ago,
        end_date: 2.days.from_now,
        lang: 'se',
      }
    end

    its('id') { is_expected.to eq course.id }

    its('language') { is_expected.to eq 'se' }

    context 'for a external course' do
      let(:course_attrs) { {status: 'active', external_course_url: 'https://example.org/test'} }

      its('state') { is_expected.to eq 'external' }
      its(['external_course_url']) { is_expected.to eq 'https://example.org/test' }
    end

    context 'for a announced course' do
      let(:course_attrs) { {status: 'active', start_date: 2.days.from_now} }

      its('state') { is_expected.to eq 'announced' }
    end

    context 'for a preview course' do
      let(:course_attrs) { {status: 'active', start_date: 2.days.ago, display_start_date: 2.days.from_now, end_date: 3.weeks.from_now} }

      its('state') { is_expected.to eq 'preview' }
    end

    context 'for a preview course without start date' do
      let(:course_attrs) { {status: 'active', start_date: nil, display_start_date: 2.days.from_now, end_date: 3.weeks.from_now} }

      its('state') { is_expected.to eq 'preview' }
    end

    context 'for a active course' do
      let(:course_attrs) { {status: 'active', start_date: 2.days.ago, display_start_date: 2.days.ago, end_date: 3.weeks.from_now} }

      its('state') { is_expected.to eq 'active' }
    end

    context 'for a self-paced course' do
      let(:course_attrs) { {status: 'active', start_date: 2.days.ago, display_start_date: 2.days.ago, end_date: 1.day.ago} }

      its('state') { is_expected.to eq 'self-paced' }
    end

    context 'for a self-paced course without end date' do
      let(:course_attrs) { {status: 'active', start_date: 2.days.ago, display_start_date: 2.days.ago, end_date: nil} }

      its('state') { is_expected.to eq 'self-paced' }
    end

    context 'with enrollment' do
      let!(:enrollment) { create(:enrollment, user_id:, course_id: course.id) }

      its('id') { is_expected.to eq course.id }

      it 'does not include description by default' do
        expect(api.rel(:courses).get.value[0].keys).not_to include 'description'
      end

      it 'includes description if wanted' do
        course_data = api.rel(:courses).get(embed: 'description').value[0]
        expect(course_data).to include 'description'
        expect(course_data['description']).to eq 'Course Characteristics --------------- ...'
      end

      it 'does not include enrollment data by default' do
        expect(request.keys).not_to include 'enrollment'
      end

      it 'includes enrollment info if wanted' do
        data = api.rel(:courses).get(embed: 'enrollment').value[0]
        expect(data['id']).to eq course.id
        expect(data.keys).to include 'enrollment'
        expect(data['enrollment'].to_h).to eq(
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

    context 'without enrollment' do
      it 'does not include enrollment info' do
        expect(api.rel(:courses).get.value[0].keys).not_to include 'enrollment'
      end

      it 'does not include description by default' do
        expect(api.rel(:courses).get.value[0].keys).not_to include 'description'
      end

      it 'includes description if wanted' do
        course_data = api.rel(:courses).get(embed: 'description').value[0]
        expect(course_data).to include 'description'
        expect(course_data['description']).to eq 'Course Characteristics --------------- ...'
      end

      its(:start_date) { is_expected.to eq course.display_start_date.iso8601(3) }
      its(:end_date) { is_expected.to eq course.end_date.iso8601(3) }

      it 'includes enrollment info if wanted' do
        data = api.rel(:courses).get(embed: 'enrollment').value[0]
        expect(data.keys).to include 'enrollment'
        expect(data['enrollment']).to be_nil
      end
    end
  end

  describe 'document filter' do
    subject(:request) { api.rel(:courses).get(params).value }

    let!(:document1) { create(:document) }
    let!(:document2) { create(:document) }
    let!(:course_a) { create(:course, :active) }
    let!(:course_b) { create(:course, :active) }
    let!(:course_c) { create(:course) }
    let(:params) { {document_id: document1.id} }

    let(:permissions) { ['course.course.index'] }
    let(:user) { {admin: true} }

    before do
      document1.courses << course_a << course_b
      document2.courses << course_c
    end

    it 'returns the correct elements' do
      expect(request.pluck('id')).to contain_exactly(course_a.id, course_b.id)
    end
  end
end
