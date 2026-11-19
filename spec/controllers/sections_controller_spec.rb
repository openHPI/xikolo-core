# frozen_string_literal: true

require 'spec_helper'

describe SectionsController, type: :controller do
  let(:permissions) { ['course.content.access', 'course.content.edit'] }
  let(:course_context) { AccountService::Context.root }
  let(:course) { create(:'course_service/course', :active, course_code: 'the_course', title: 'Test Course') }
  let!(:section) { create(:'course_service/section', course:, position: 1) }

  before do
    sign_in(permissions:)
  end

  describe 'GET #index' do
    subject(:request) { get :index, params: {course_id: course.id} }

    it 'answers with a page' do
      expect(request.status).to eq 200
    end
  end

  describe 'POST move' do
    it 'changes position to 4' do
      post :move, params: {id: section.id, course_id: course.id, position: 4}

      expect(section.reload.position).to eq 4
    end

    context 'to the bottom' do
      let!(:other_section) { create(:'course_service/section', course:, position: 2) }

      it 'places the section after all its siblings' do
        post :move, params: {id: section.id, course_id: course.id, position: 'bottom'}

        expect(section.reload.position).to eq(other_section.position + 1)
      end
    end
  end
end
