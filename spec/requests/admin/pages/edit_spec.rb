# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Page: Edit', type: :request do
  subject(:action) { put '/pages/imprint', params:, headers: }

  let(:params) do
    {locale: 'en', page: {name: 'imprint', title: 'New title', locale: 'en', text: 'New text'}}
  end
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

  before do
    stub_user_request permissions: %w[helpdesk.page.store]
  end

  context 'without any preexisting pages' do
    it 'creates a new page record' do
      expect { action }.to change(Page, :count).from(0).to(1)
    end
  end

  context 'with existing page in different language' do
    before { create(:page, :german, name: 'imprint') }

    it 'creates a new page record' do
      expect { action }.to change(Page, :count).from(1).to(2)
    end
  end

  context 'with existing page in same language' do
    let!(:page) { create(:page, :english, name: 'imprint') }

    it 'updates the existing page record' do
      expect { action }.not_to change(Page, :count).from(1)
      expect(page.reload.title).to eq 'New title'
    end
  end

  context 'for richtext with valid uploads' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }

    let(:params) do
      {locale: 'en', page: {name: 'imprint', title: 'Imprint', locale: 'en', text:}}
    end

    it 'stores the upload and creates a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'helpdesk_page_file',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /pages/imprint/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      move_file_stub = stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')

      action

      expect(Page.count).to eq(1)
      expect(move_file_stub).to have_been_requested
    end

    it 'rejects invalid upload and does not create a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'helpdesk_page_file',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      action

      expect(response.body).to include 'Your file upload has been rejected due to policy violations.'
      expect(Page.count).to eq 0
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'helpdesk_page_file',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /pages/imprint/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      action

      expect(response.body).to include 'Your file upload could not be stored'
      expect(Page.count).to eq 0
    end
  end
end
