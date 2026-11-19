# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Teachers: List', type: :request do
  subject(:list_teachers) { get '/teachers', headers: }

  let(:headers) { {} }
  let(:page) { Capybara.string(response.body) }

  context 'for anonymous users' do
    it 'redirects the user' do
      list_teachers
      expect(response).to have_http_status :see_other
    end
  end

  context 'for logged in users' do
    let(:user) { create(:'account_service/user') }

    before { sign_in(user:) }

    context 'without permissions' do
      it 'redirects the user' do
        list_teachers
        expect(response).to have_http_status :see_other
      end
    end

    context 'with permission' do
      let(:user) { create(:'account_service/user') }

      before do
        role = create(:'account_service/role', permissions: ['course.teacher.view'])
        create(:'account_service/grant', principal: user, role:)
        sign_in(user:)
      end

      context 'with teachers' do
        before do
          create(:'course_service/teacher', name: 'Tom Teacher')
          create(:'course_service/teacher', name: 'Hans Otto')
        end

        it 'lists all teachers' do
          list_teachers
          expect(response).to have_http_status :ok
          expect(page).to have_text 'Tom Teacher'
          expect(page).to have_text 'Hans Otto'
          expect(page).to have_no_link 'Reset all filters'
        end
      end

      context 'with no teachers' do
        it 'shows the empty state' do
          list_teachers
          expect(response).to have_http_status :ok
          expect(page).to have_text 'There are no teachers yet.'
        end
      end

      context 'when filtering by name' do
        before do
          create(:'course_service/teacher', name: 'Tom Teacher')
          create(:'course_service/teacher', name: 'Hans Otto')
        end

        it 'shows matching teachers' do
          get '/teachers', params: {q: 'Tom Teacher'}
          expect(page).to have_field 'Search', with: 'Tom Teacher'
          expect(page).to have_link 'Reset all filters', href: teachers_path
          expect(page).to have_text 'Tom Teacher'
          expect(page).to have_no_text 'Hans Otto'
        end

        it 'shows no results state when nothing matches' do
          get '/teachers', params: {q: 'Adam Admin'}
          expect(page).to have_text "Sorry, we couldn't find any matching entry."
        end
      end

      context 'as an XHR request' do
        let(:headers) { {'X-Requested-With': 'XMLHttpRequest'} }

        it 'returns teacher data as JSON' do
          tom = create(:'course_service/teacher', name: 'Tom Teacher')

          list_teachers

          expect(response).to have_http_status :ok
          expect(response.parsed_body).to include(
            hash_including('id' => tom.id, 'text' => 'Tom Teacher')
          )
        end

        it 'filters by query' do
          create(:'course_service/teacher', name: 'Tom Teacher')
          create(:'course_service/teacher', name: 'Hans Otto')

          get '/teachers', params: {q: 'Tom Teacher'}, headers: headers

          expect(response.parsed_body).to include(hash_including('text' => 'Tom Teacher'))
          expect(response.parsed_body).not_to include(hash_including('text' => 'Hans Otto'))
        end
      end
    end
  end
end
