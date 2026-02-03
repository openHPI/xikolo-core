# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: Create', type: :request do
  subject(:create_offer) do
    post "/courses/#{course.course_code}/offers", params:, headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:params) { {course_offer: {price: 12}} }
  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }

  before do
    stub_user_request(permissions:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return(Stub.json([]))
  end

  it 'creates a new course offer' do
    expect { create_offer }.to change(Course::Offer, :count).from(0).to(1)
    expect(Course::Offer.all).to contain_exactly(an_object_having_attributes(
      course_id: course.id,
      price: 1200
    ))
    expect(flash[:success].first).to eq('The offer has been created.')
    expect(response).to redirect_to course_offers_path
  end

  context 'with an invalid price' do
    let(:params) { {course_offer: {price: -100}} }

    it 'displays an error message' do
      expect { create_offer }.not_to change(Course::Offer, :count).from(0)
      expect(flash[:error].first).to eq('The offer could not be created.')
      expect(response.body).to render_template :new
    end
  end

  context 'without permission to manage course offers' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      create_offer
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[course.course.edit] }

    it 'redirects the user' do
      create_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      create_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
