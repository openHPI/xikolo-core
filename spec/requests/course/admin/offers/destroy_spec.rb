# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: Destroy', type: :request do
  subject(:destroy_offer) do
    delete "/courses/#{course.course_code}/offers/#{offer.id}", headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:offer) { create(:offer, course_id: course.id) }

  before do
    stub_user_request(permissions:)
    offer

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  it 'deletes the course offer' do
    expect { destroy_offer }.to change(Course::Offer, :count).from(1).to(0)
    expect(response).to redirect_to course_offers_path
    expect(flash[:success].first).to eq('The offer has been deleted.')
  end

  context 'without permission to manage course offers' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      destroy_offer
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[course.course.edit] }

    it 'redirects the user' do
      destroy_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      destroy_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
