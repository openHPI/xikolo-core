# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: Update', type: :request do
  subject(:update_offer) do
    patch "/learn/#{course.course_code}/offers/#{offer.id}", params:
  end

  let(:params) { {course_offer: {price: 12}} }
  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course, :active) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:offer) { create(:offer, course_id: course.id) }

  before do
    sign_in(user:) if authenticate
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  it 'updates the course offer' do
    expect { update_offer }.to change { offer.reload.price }.from(1000).to(1200)
    expect(flash[:success].first).to eq('The offer has been updated.')
    expect(response).to redirect_to "/learn/#{course.course_code}/offers"
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
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects the user' do
      update_offer
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end
end
