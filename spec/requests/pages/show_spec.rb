# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Page: Show', type: :request do
  describe '(rendering)' do
    it 'renders public URLs for references to files stored on S3' do
      create(:page, name: 'faq', locale: 'en', title: 'FAQ', text: 'Read! s3://xikolo-public/pages/faq/image1.jpg')

      get '/pages/faq'

      expect(response.body).not_to include 's3://xikolo-public/pages/faq/image1.jpg'
      expect(response.body).to include 'https://s3.xikolo.de/xikolo-public/pages/faq/image1.jpg'
    end

    it 'renders Markdown content as HTML' do
      create(:page, name: 'faq', locale: 'en', title: 'FAQ', text: <<~MD.strip)
        ## What is Xikolo?
        Answer 1

        ## What is it not?
        Answer 2
      MD

      get '/pages/faq'

      expect(response.body).not_to include '## What is Xikolo?'
      expect(response.body).to include '<h2 id="what-is-xikolo">What is Xikolo?</h2>'
    end
  end

  context 'as anonymous user' do
    it 'can access existing pages' do
      create(:page, :english, name: 'imprint')

      get '/pages/imprint'

      expect(response.body).to include('<title>English Title')
      expect(response.body).to include('English Text')
      expect(response.body).to include('last changed')
    end

    it 'returns translated content if requested' do
      create(:page, :english, name: 'imprint')
      create(:page, :german, name: 'imprint')

      get '/pages/imprint?locale=de'

      expect(response.body).to include('<title>Deutscher Titel')
      expect(response.body).to include('Deutscher Text')
      expect(response.body).to include('Diese Seite wurde zuletzt')
    end

    it 'returns the content in the fallback language if requested translation is missing' do
      create(:page, :english, name: 'imprint')

      get '/pages/imprint?locale=de'

      expect(response.body).to include('<title>English Title')
      expect(response.body).to include('English Text')
      expect(response.body).to include('Diese Seite wurde zuletzt') # User interface is German as requested
    end

    it 'returns translated content if only non-default translations exist' do
      create(:page, :german, name: 'imprint')

      get '/pages/imprint'

      expect(response.body).to include('<title>Deutscher Titel')
      expect(response.body).to include('Deutscher Text')
      expect(response.body).to include('last changed') # User interface is English as requested
    end

    it 'shows 404 Not Found for missing pages' do
      expect do
        get '/pages/missing'
      end.to raise_error AbstractController::ActionNotFound
    end
  end

  context 'as admin' do
    before do
      stub_user_request permissions: %w[helpdesk.page.store]
    end

    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'returns the requested content as well as buttons for creating/editing translations' do
      create(:page, :english, name: 'imprint')
      create(:page, :german, name: 'imprint')

      get('/pages/imprint', headers:)

      expect(response.body).to include('<title>English Title')
      expect(response.body).to include('English Text')
      expect(response.body).to include('last changed')

      # "Edit" for existing translations
      expect(response.body).to include 'Edit German translation "Deutscher Titel"'
      expect(response.body).to include 'Edit English translation "English Title"'
    end

    it 'shows an error page with buttons for creating translations for missing pages' do
      get('/pages/missing', headers:)

      expect(response.body).not_to include('last changed')

      expect(response.body).to include 'We are sorry, but the page you are looking for could not be found'
      expect(response.body).to include 'Go to helpdesk'

      # "Add" for missing translations
      expect(response.body).to include 'Add German translation'
      expect(response.body).to include 'Add English translation'
    end

    it 'shows the oldest translation with the correct buttons when only non-default translations exist' do
      create(:page, name: 'imprint', locale: 'de', title: 'German Title', created_at: 1.day.ago)

      get('/pages/imprint', headers:)

      expect(response.body).to include '<title>German Title'
      expect(response.body).to include 'last changed'

      expect(response.body).not_to include 'We are sorry, but the page you are looking for could not be found'
      expect(response.body).not_to include 'Go to helpdesk'

      # "Add" for missing translations
      expect(response.body).to include 'Add English translation'

      # "Edit" for existing translations
      expect(response.body).to include 'Edit German translation "German Title"'
    end
  end
end
