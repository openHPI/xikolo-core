# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Shorts: Index', type: :request do
  before do
    create(:'course_service/short', title_translations: {'de' => 'Aktives short', 'en' => 'Active short'}, status: 'active')
    create(:'course_service/short', title_translations: {'de' => 'Archiviertes short', 'en' => 'Archived short'}, status: 'archived')
    create(:'course_service/short', title_translations: {'de' => 'Short in Vorbereitung', 'en' => 'Short in preparation'}, status: 'preparation')
  end

  context 'when trying to access the admin shorts index' do
    subject(:request) { get '/admin/shorts' }

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
        expect(response).to redirect_to('http://www.example.com/')
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
        expect(response).to redirect_to('http://www.example.com/')
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists all shorts' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Active short'
          expect(page).to have_text 'active'
          expect(page).to have_text 'Archived short'
          expect(page).to have_text 'archived'
          expect(page).to have_text 'Short in preparation'
          expect(page).to have_text 'preparation'
        end
      end
    end
  end

  context 'as logged-in admin user' do
    let(:user) { create(:'account_service/user', :admin) }

    before { sign_in(user:) }

    describe 'currently running shorts (active filter)' do
      subject(:request) { get '/admin/shorts?status=active' }

      let(:page) { Capybara.string(response.body) }

      it 'lists only currently running non-hidden courses' do
        request
        expect(response).to have_http_status :ok

        expect(page).to have_text 'Active short'
        expect(page).to have_no_text 'Archived short'
        expect(page).to have_no_text 'Short in preparation'
      end
    end

    describe 'shorts in preparation' do
      subject(:request) { get '/admin/shorts?status=preparation' }

      let(:page) { Capybara.string(response.body) }

      it 'lists all courses in preparation' do
        request
        expect(response).to have_http_status :ok

        expect(page).to have_text 'Short in preparation'
      end
    end

    describe 'archived shorts' do
      subject(:request) { get '/admin/shorts?status=archived' }

      let(:page) { Capybara.string(response.body) }

      it 'lists all archived shorts' do
        request
        expect(response).to have_http_status :ok

        expect(page).to have_text 'Archived short'
        expect(page).to have_no_text 'Active short'
        expect(page).to have_no_text 'Short in preparation'
      end
    end

    describe 'autocomplete filter' do
      subject(:request) { get '/admin/shorts?&autocomplete=active+short' }

      let(:page) { Capybara.string(response.body) }

      it 'filters shorts by a given string' do
        request
        expect(page).to have_text 'Active short'
        expect(page).to have_no_text 'Archived short'
        expect(page).to have_no_text 'Short in preparation'
      end
    end
  end
end
