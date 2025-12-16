# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Show', type: :request do
  let(:api) { Restify.new(course_service.root_url).get.value! }
  let(:course) { create(:'course_service/course', course_params) }
  let(:desc_rt) { 'Headline\n--\n s3://xikolo-public/courses/34/rtfiles/3/hans.jpg' }
  let(:desc_rendered) { 'Headline\n--\n https://s3.xikolo.de/xikolo-public/courses/34/rtfiles/3/hans.jpg' }
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

    it { is_expected.to have_relation :prerequisite_status }
  end

  context 'in raw format' do
    subject(:show) { api.rel(:course).get({id: course.course_code, raw: true}).value! }

    it 'returns the inlined description for editing' do
      expect(show['description']).to eq(
        'url_mapping' => {
          's3://xikolo-public/courses/34/rtfiles/3/hans.jpg' \
            => 'https://s3.xikolo.de/xikolo-public/courses/34/rtfiles/3/hans.jpg',
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

    context 'external registration URL' do
      describe 'invite-only course, with external registration' do
        let(:course_params) do
          {invite_only: true, external_registration_url: {en: 'http://foo.bar'}}
        end

        it 'returns the external registration URLs from the course' do
          expect(show['external_registration_url']['en']).to eq 'http://foo.bar'
        end
      end

      describe 'invite-only course' do
        let(:course_params) { {invite_only: true} }

        it { expect(show['external_registration_url']).to be_nil }
      end

      describe 'external registration course' do
        let(:course_params) { {external_registration_url: {en: 'http://foo.bar'}} }

        it { expect(show['external_registration_url']['en']).to eq 'http://foo.bar' }
      end
    end
  end
end
