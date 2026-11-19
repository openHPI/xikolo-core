# frozen_string_literal: true

require 'spec_helper'

describe 'Courses: List', type: :request do
  subject(:resource) { api.rel(:courses).get(params).value! }

  let(:api)    { restify_with_headers(course_service.root_url).get.value }
  let(:params) { {} }

  describe 'autocomplete filter' do
    let!(:data_course) { create(:'course_service/course', title: 'data things and more words') }
    let(:params) { {autocomplete: 'things'} }

    before do
      create(:'course_service/course', title: 'nothing with the given search string')
      create(:'course_service/course', course_code: 'data_2017')
    end

    it 'filters courses by a given string' do
      expect(resource.pluck('id')).to contain_exactly(data_course.id)
    end
  end

  describe 'group restricted course' do
    let(:group)       { 'group.1' }
    let(:other_group) { 'group.other' }

    let!(:courses) do
      [
        create(:'course_service/course', groups: []),
        create(:'course_service/course', groups: [group]),
        create(:'course_service/course', groups: [other_group]),
      ]
    end

    it 'does not include restricted course' do
      expect(resource.pluck('id')).to eq [courses[0].id]
    end
  end
end
