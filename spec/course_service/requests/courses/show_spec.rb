# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Show', type: :request do
  let(:api) { restify_with_headers(course_service.root_url).get.value! }
  let(:course) { create(:'course_service/course', course_params) }
  let(:desc_rt) { 'Headline\n--\n s3://xikolo-public/courses/34/rtfiles/3/hans.jpg' }
  let(:desc_rendered) { "Headline\\n--\\n #{test_s3_host}/xikolo-public/courses/34/rtfiles/3/hans.jpg" }
  let(:course_params) { {description: desc_rt, groups: ['xikolo.admin']} }

  context 'with case-insensitive course code' do
    subject(:show) { api.rel(:course).get({id: 'CoUrSe-cOdE'}).value! }

    let!(:course) { create(:'course_service/course', course_code: 'course-code') }

    it 'responds with 200 Ok' do
      expect(show).to respond_with :ok
    end

    it 'returns the correct course' do
      expect(show['id']).to eq course.id
    end
  end

  context 'in normal format' do
    subject(:show) { api.rel(:course).get({id: course.course_code}).value! }

    it 'returns the inlined description with external URLs' do
      expect(show['description']).to eq desc_rendered
    end
  end

  context 'in raw format' do
    subject(:show) { api.rel(:course).get({id: course.course_code, raw: true}).value! }

    it 'returns the inlined description for editing' do
      expect(show['description']).to eq(
        'url_mapping' => {
          's3://xikolo-public/courses/34/rtfiles/3/hans.jpg' \
            => "#{test_s3_host}/xikolo-public/courses/34/rtfiles/3/hans.jpg",
        },
        'other_files' => {
          's3://xikolo-public/courses/34/rtfiles/3/hans.jpg' => 'hans.jpg',
        },
        'markup' => desc_rt
      )
      expect(show.response.headers.keys.map(&:downcase)).not_to include 'x_cache_xikolo'
    end

    it 'returns allowed groups' do
      expect(show['groups']).to eq ['xikolo.admin']
    end
  end
end
