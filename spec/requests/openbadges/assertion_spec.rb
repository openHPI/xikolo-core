# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Course: Assertion', type: :request do
  subject(:assertion_response) { get "/courses/#{course.id}/openbadges/v2/assertion/#{badge.id}"; response }

  let(:course) { create(:course, records_released: true) }
  let(:user) { create(:user) }
  let(:record) { create(:roa, course:, user:) }
  let(:badge) { create(:open_badge_v2, :baked, record:) }

  let(:response_body) { JSON.parse(assertion_response.body) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
    ).to_return(
      Stub.json(
        build_list(
          :'course:enrollment', 1,
          course_id: course.id,
          user_id: user.id,
          points: {achieved: 90, maximal: 100, percentage: 90},
          certificates: {record_of_achievement: true, certificate: true},
          quantile: 0.99
        )
      )
    )
  end

  context 'when open_badges option enabled in config' do
    before do
      xi_config <<~YML
        open_badges:
          enabled: true
      YML
    end

    it 'returns correct HTTP status' do
      expect(assertion_response).to have_http_status :ok
    end

    it 'returns valid json' do
      expect(assertion_response.header['Content-Type']).to eql('application/json; charset=utf-8')
      expect { response_body }.not_to raise_error
    end

    it 'returns valid badge structure' do
      expect(response_body).to match hash_including(
        '@context' => instance_of(String),
        'id' => instance_of(String),
        'evidence' => instance_of(String),
        'issuedOn' => instance_of(String),
        'verification' => hash_including(
          'type', 'creator'
        ),
        'recipient' => hash_including(
          'type', 'hashed', 'identity'
        )
      )
    end

    it 'returns valid badge attributes' do
      expect(response_body['@context']).to eql('https://w3id.org/openbadges/v2')
      expect(response_body['type']).to eql('Assertion')
      expect(DateTime.parse(response_body['issuedOn'])).to be_an_instance_of(DateTime)
      expect(response_body['recipient']['hashed']).to be_truthy
      expect(response_body['recipient']['identity']).to eql("sha256$#{Digest::SHA256.hexdigest('mail@mail.de')}")
      expect(response_body['verification']['type']).to eql('signed')
    end
  end

  context 'with non-existing assertion' do
    subject(:assertion_response) { get "/courses/#{course.id}/openbadges/v2/assertion/#{SecureRandom.uuid}"; response }

    it 'returns not_found HTTP status' do
      expect(assertion_response).to have_http_status :not_found
    end
  end

  context 'when open_badges option disabled in config' do
    before do
      xi_config <<~YML
        open_badges:
          enabled: false
      YML
    end

    it 'returns not_found HTTP status' do
      expect(assertion_response).to have_http_status :not_found
    end

    it 'returns nothing' do
      expect(assertion_response.body).to be_empty
    end
  end
end
