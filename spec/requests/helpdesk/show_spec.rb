# frozen_string_literal: true

require 'spec_helper'

describe 'Helpdesk: Show', type: :request do
  subject(:resp) { get('/helpdesk', headers:); response }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:features) { {} }
  let(:course) { build(:'course:course', id: generate(:course_id), title: 'First course') }
  let(:page) { Capybara.string(resp.body) }

  before do
    Stub.request(
      :course, :get, '/courses',
      query: hash_including(public: 'true', hidden: 'false')
    ).to_return Stub.json([course])

    stub_user_request features:
  end

  it 'lists the category groups' do
    expect(resp.body).to include 'General question', 'Course-specific question'
  end

  it 'contains the expected options for the category' do
    expect(page).to have_select 'category', options: ['Technical question', 'First course']
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
