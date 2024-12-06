# frozen_string_literal: true

require 'spec_helper'

describe 'Transpipe API: List courses', type: :request do
  subject(:request) do
    get '/bridges/transpipe/courses', headers:, params:
  end

  before do
    Stub.service(:course, build(:'course:root'))
    stub_course_list
  end

  let(:headers) { {'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966'} }
  let(:params) { {} }
  let(:json) { JSON.parse response.body }

  let(:stub_course_list) do
    Stub.request(:course, :get, '/courses', query: hash_including(:page))
      .to_return Stub.json([
        build(:'course:course'),
        build(:'course:course'),
        build(:'course:course'),
        build(:'course:course'),
      ])
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end

    it 'answers in context of the configured realm' do
      request
      expect(response.header['WWW-Authenticate']).to include('realm="test-realm"')
    end
  end

  it 'responds with the correct object structure' do
    request
    expect(response).to have_http_status :ok
    expect(json.length).to eq 4
    expect(json.first).to include(
      'title',
      'abstract',
      'language',
      'start-date',
      'end-date',
      'status',
      'id'
    )
  end

  describe 'pagination' do
    context 'when another page exists' do
      let(:stub_course_list) do
        Stub.request(:course, :get, '/courses', query: hash_including(page: '1'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {next: '/courses?p=2'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '2'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=1'}
          )
      end

      it 'also links to the next page in the response header' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Link']).to match(/<.+\?page=2>; rel="next"/)
        expect(json.length).to eq 3
      end
    end

    context 'when there is a previous and a next page' do
      let(:params) { {page: 2} }
      let(:stub_course_list) do
        Stub.request(:course, :get, '/courses', query: hash_including(page: '1'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {next: '/courses?p=2'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '2'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=1', next: '/courses?p=3'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '3'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=2'}
          )
      end

      it 'links to both the previous and the next page in the response header' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Link']).to match(/<.+\?page=1>; rel="prev"/)
        expect(response.headers['Link']).to match(/<.+\?page=3>; rel="next"/)
        expect(json.length).to eq 3
      end
    end
  end
end
