# frozen_string_literal: true

require 'spec_helper'

describe 'Chatbot Bridge API: Courses: Index', type: :request do
  subject(:request) do
    get '/bridges/chatbot/courses', headers:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/courses',
      query: {
        hidden: false,
      }
    ).to_return Stub.json(build_list(:'course:course', 4))
    request
  end

  it 'responds with all courses' do
    expect(response).to have_http_status :ok
    expect(json).to all include('id', 'title', 'course_code', 'start_date', 'language', 'self_paced', 'certificates')
    expect(json.length).to eq(4)
  end

  context 'without Authorization header' do
    let(:headers) { {} }

    it 'complains about missing authorization' do
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('You must provide an Authorization header to access this resource.')
    end
  end

  context 'with Invalid Signature' do
    let(:token) { 'Bearer 123123' }
    let(:headers) { {'Authorization' => token} }

    it 'complains about an invalid signature' do
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('Invalid Signature')
    end
  end
end
