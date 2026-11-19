# frozen_string_literal: true

require 'spec_helper'

describe 'Helpdesk: Show', type: :request do
  subject(:resp) { get('/helpdesk', headers:); response }

  let(:headers) { {} }
  let(:course) { build(:'course:course', id: generate(:course_id), title: 'First course') }
  let(:page) { Capybara.string(resp.body) }
  let(:user) { create(:'account_service/user') }

  before do
    Stub.request(
      :course, :get, '/courses',
      query: hash_including(public: 'true')
    ).to_return Stub.json([course])

    sign_in(user:)
  end

  it 'lists the category groups' do
    expect(resp.body).to include 'General question', 'Course-specific question'
  end

  it 'contains the expected options for the category' do
    expect(page).to have_select 'category', options: ['Technical question', 'openHPI Course Reactivation', 'First course']
  end

  context 'a direct GET request' do
    it 'renders the helpdesk form within a typical layout' do
      expect(resp.body).to include '<html'
      expect(resp.body).to include '<nav'
      expect(resp.body).to include 'Dashboard'
    end
  end

  context 'an AJAX request (as triggered by the helpdesk slide-in)' do
    let(:headers) { super().merge('X-Requested-With' => 'XMLHttpRequest') }

    it 'renders only the form, without any layout' do
      expect(resp.body).not_to include '<html'
      expect(resp.body).not_to include '<nav'
      expect(resp.body).not_to include 'Dashboard'

      expect(resp.body).to include 'General question', 'Course-specific question'
    end
  end
end
