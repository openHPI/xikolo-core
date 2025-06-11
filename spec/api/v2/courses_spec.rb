# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Courses::Courses, type: :request do
  before do
    Stub.service(:course, build(:'course:root'))
    Stub.service(
      :account,
      session_url: 'http://localhost:3100/sessions/{id}{?embed,context}'
    )
  end

  describe 'GET courses' do
    subject { get '/api/v2/courses', params: {format: 'json'} }

    let(:course1) { {id: '123'} }
    let(:course2) { {id: '456'} }

    before do
      Stub.request(
        :course, :get, '/api/v2/course/courses',
        query: {embed: 'enrollment', page: '1', per_page: '500'}
      ).to_return Stub.json([course1, course2])
    end

    describe '(response)' do
      subject { super(); response }

      it { is_expected.to have_http_status :ok }
    end

    describe '(json)' do
      subject { super(); JSON.parse response.body }

      it { is_expected.not_to have_attribute 'description' }
      it { is_expected.not_to have_attribute 'teaser_stream' }
    end
  end

  describe 'GET courses/:id' do
    subject(:get_course) do
      get "/api/v2/courses/#{course.id}", params: {format: 'json'}
    end

    let(:course) { create(:course) }

    before do
      Stub.request(
        :course, :get, "/api/v2/course/courses/#{course.id}",
        query: {embed: 'description,enrollment'}
      ).to_return Stub.json({id: course.id})
    end

    describe '(response)' do
      subject { get_course; response }

      it { is_expected.to have_http_status :ok }
    end

    describe '(json)' do
      subject { get_course; json }

      let(:json) { JSON.parse(response.body) }

      it { is_expected.to be_a Hash }

      it { is_expected.to have_type 'courses' }
      it { is_expected.to have_id course.id }

      it { is_expected.to have_attribute 'title' }
      it { is_expected.to have_attribute 'slug' }
      it { is_expected.to have_attribute 'start_at' }
      it { is_expected.to have_attribute 'end_at' }
      it { is_expected.to have_attribute 'abstract' }
      it { is_expected.to have_attribute 'description' }
      it { is_expected.to have_attribute 'language' }
      it { is_expected.to have_attribute 'status' }
      it { is_expected.to have_attribute 'teachers' }
      it { is_expected.to have_attribute 'accessible' }
      it { is_expected.to have_attribute 'enrollable' }
      it { is_expected.to have_attribute 'hidden' }
      it { is_expected.to have_attribute 'external' }
      it { is_expected.to have_attribute 'certificates' }
      it { is_expected.to have_attribute 'teaser_stream' }

      describe '[teaser_stream]' do
        subject(:teaser) { get_course; json.dig('data', 'attributes', 'teaser_stream') }

        let(:course) { create(:course, :with_teaser_video, video:) }
        let(:video) { create(:video) }

        it 'provides media info about the teaser stream' do
          expect(teaser).to match hash_including(
            'hd_url' => video.pip_stream.hd_url,
            'sd_url' => video.pip_stream.sd_url,
            'thumbnail_url' => video.pip_stream.poster
          )
        end
      end
    end
  end
end
