# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: List', type: :request do
  subject(:list_offers) do
    get "/learn/#{course.course_code}/offers"
  end

  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }

  before do
    sign_in(user:) if authenticate
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

    create(:offer, course_id: course.id, price: 10_050)
    create(:offer, course_id: course.id, price: 10_099, payment_frequency: 'quarterly')

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return(Stub.json(course_resource))
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
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects the user' do
      list_offers
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end
end
