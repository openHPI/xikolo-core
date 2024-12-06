# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: Update', type: :request do
  subject(:update_offer) do
    patch "/courses/#{course.course_code}/offers/#{offer.id}", params:, headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:params) { {course_offer: {price: 12}} }
  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:offer) { create(:offer, course_id: course.id) }

  before do
    stub_user_request(permissions:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return(Stub.json([]))
  end

  it 'updates the course offer' do
    expect { update_offer }.to change { offer.reload.price }.from(1000).to(1200)
    expect(flash[:success].first).to eq('The offer has been updated.')
    expect(response).to redirect_to "/courses/#{course.course_code}/offers"
  end

  context 'with an invalid price' do
    let(:params) { {course_offer: {price: -100}} }

    it 'displays an error message' do
      expect { update_offer }.not_to change { offer.reload.price }
      expect(flash[:error].first).to eq('The offer could not be updated.')
      expect(response.body).to render_template :edit
    end
  end

  context 'without permission to manage course offers' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      update_offer
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[course.course.edit] }

    it 'redirects the user' do
      update_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      update_offer
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
