# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: List', type: :request do
  subject(:list_offers) do
    get "/courses/#{course.course_code}/offers", headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }

  before do
    stub_user_request(permissions:)

    create(:offer, course_id: course.id, price: 10_050)
    create(:offer, course_id: course.id, price: 10_099, payment_frequency: 'quarterly')

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return(Stub.json(course_resource))
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return(Stub.json([]))
  end

  it 'lists all course offers' do
    list_offers

    expect(response).to have_http_status :ok
    expect(response.body).to include('Offers')
    # Offer 1
    expect(response.body).to include('One-time')
    expect(response.body).to include('EUR100.50')
    # Offer 2
    expect(response.body).to include('Quarterly')
    expect(response.body).to include('EUR100.99')
  end

  context 'without permission to list course offers' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      list_offers
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[course.course.edit] }

    it 'redirects the user' do
      list_offers
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      list_offers
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
