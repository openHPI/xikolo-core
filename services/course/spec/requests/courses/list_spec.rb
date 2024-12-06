# frozen_string_literal: true

require 'spec_helper'

describe 'Courses: List', type: :request do
  subject(:resource) { api.rel(:courses).get(params).value! }

  let(:api)    { Restify.new(:test).get.value }
  let(:params) { {} }

  describe 'autocomplete filter' do
    let!(:data_course) { create(:course, title: 'data things and more words') }
    let(:params) { {autocomplete: 'things'} }

    before do
      create(:course, title: 'nothing with the given search string')
      create(:course, course_code: 'data_2017')
    end

    it 'filters courses by a given string' do
      expect(resource.pluck('id')).to contain_exactly(data_course.id)
    end
  end

  context 'external registration URL' do
    let(:course_attrs) { {} }

    before { create(:course, course_attrs) }

    describe 'invite-only course, with external registration' do
      let(:course_attrs) do
        {invite_only: true, external_registration_url: {en: 'http://foo.bar'}}
      end

      it 'returns the external registration URLs from the course' do
        expect(resource.first['external_registration_url']['en']).to eq 'http://foo.bar'
      end
    end

    describe 'invite-only course' do
      let(:course_attrs) { {invite_only: true} }

      it { expect(resource.first).not_to include 'external_registration_url' }
    end

    describe 'external registration course' do
      let(:course_attrs) { {external_registration_url: {en: 'http://foo.bar'}} }

      it { expect(resource.first).not_to include 'external_registration_url' }
    end
  end

  describe 'group restricted course' do
    let(:group)       { 'group.1' }
    let(:other_group) { 'group.other' }

    let!(:courses) do
      [
        create(:course, groups: []),
        create(:course, groups: [group]),
        create(:course, groups: [other_group]),
      ]
    end

    it 'does not include restricted course' do
      expect(resource.map(&:id)).to eq [courses[0].id]
    end

    context 'with user_id filter' do
      let(:params) { {user_id:} }
      let(:user_id) { generate(:user_id) }

      before do
        create(:enrollment, course: courses[0], user_id:)
        create(:enrollment, course: courses[1], user_id:)
      end

      it 'includes restricted courses the user is enrolled' do
        expect(resource.map(&:id)).to contain_exactly(courses[0].id, courses[1].id)
      end
    end

    context 'with promoted_for filter' do
      let(:params) { {promoted_for: user_id} }
      let(:user_id) { generate(:user_id) }

      let!(:courses) do
        [
          create(:course, :active, groups: []),
          create(:course, :active, groups: []),
          create(:course, :active, groups: [group]),
          create(:course, :active, groups: [group]),
          create(:course, :active, groups: [other_group]),
        ]
      end

      before do
        create(:enrollment, course: courses[0], user_id:)
        create(:enrollment, course: courses[2], user_id:)

        Stub.request(
          :account, :get, '/groups', query: {user: user_id, per_page: 1000}
        ).to_return Stub.json([{name: group}, {name: 'group.third'}])
      end

      it 'includes restricted courses the user is not enrolled but allowed to see' do
        expect(resource.map(&:id)).to contain_exactly(courses[1].id, courses[3].id)
      end
    end
  end
end
