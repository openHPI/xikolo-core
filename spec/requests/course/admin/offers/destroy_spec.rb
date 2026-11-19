# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Offers: Destroy', type: :request do
  subject(:destroy_offer) do
    delete "/learn/#{course.course_code}/offers/#{offer.id}"
  end

  let(:permissions) { %w[course.course.edit course.content.access] }
  let(:course) { create(:course) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:offer) { create(:offer, course_id: course.id) }

  before do
    sign_in(user:) if authenticate
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)
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
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects the user' do
      destroy_offer
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end
end
