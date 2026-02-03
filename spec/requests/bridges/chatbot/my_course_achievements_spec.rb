# frozen_string_literal: true

require 'spec_helper'

describe 'Chatbot Bridge API: My Course Achievements', type: :request do
  subject(:request) do
    get "/bridges/chatbot/my_courses/#{course['id']}/achievements", headers:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }
  let(:course) { build(:'course:course') }
  let(:achievement) { [build(:'course:achievement', :cop), build(:'course:achievement', :roa)] }
  let(:stub_course) do
    Stub.request(:course, :get, "/courses/#{course['id']}")
      .to_return Stub.json(course)
  end
  let(:stub_achievements) do
    Stub.request(
      :course, :get, "/courses/#{course['id']}/achievements",
      query: {
        user_id:,
      }
    ).to_return Stub.json(achievement)
  end

  before do
    stub_course
    stub_achievements
  end

  it 'responds with achievements' do
    request
    expect(response).to have_http_status :ok
    expect(json['certificates']).to contain_exactly(hash_including(
      'type' => 'confirmation_of_participation',
      'name' => 'Confirmation of Participation',
      'description' => 'Certificate description',
      'achieved' => true,
      'achievable' => true,
      'requirements' => 'Certificate requirements',
      'download' => nil
    ), hash_including(
      'type' => 'record_of_achievement',
      'name' => 'Record of Achievement',
      'description' => 'Certificate description',
      'achieved' => true,
      'achievable' => true,
      'requirements' => 'Certificate requirements',
      'download' => nil
    ))
    expect(json['points']).to match hash_including('achieved' => 2.0, 'total' => 2.0, 'percentage' => 100)
    expect(json['visits']).to match hash_including('achieved' => 2, 'total' => 2, 'percentage' => 100)
  end

  context 'without Authorization header' do
    let(:headers) { {} }

    it 'complains about missing authorization' do
      request
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('You must provide an Authorization header to access this resource.')
    end
  end

  context 'with Invalid Signature' do
    let(:token) { 'Bearer 123123' }
    let(:headers) { {'Authorization' => token} }

    it 'complains about an invalid signature' do
      request
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('Invalid Signature')
    end
  end

  context 'with Accept-Language header present' do
    let(:headers) { super().merge('Accept-Language' => 'de') }

    it 'fulfils the request with the same header present' do
      request
      expect(stub_achievements.with(headers: {'Accept-Language' => 'de'})).to have_been_requested
    end
  end
end
