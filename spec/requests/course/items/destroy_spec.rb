# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Destroy', type: :request do
  subject(:action) do
    delete("/learn/#{course.course_code}/sections/#{section.id}/items/#{item.id}")
  end

  let(:course) { create(:'course_service/course', course_code: 'example') }
  let(:section) { create(:'course_service/section', course_id: course.id) }
  let(:item) { create(:'course_service/item') }
  let(:item_resource) { item.decorate.as_json }
  let(:params) { {} }

  context 'for anonymous user' do
    it 'redirects to login page' do
      action
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'for a logged in user' do
    let(:user) { create(:'account_service/user') }
    let(:delete_item_stub) { Stub.request(:course, :delete, "/items/#{item.id}").to_return(status: 200) }

    before do
      sign_in(user:)
    end

    it 'is forbidden without proper permissions' do
      action
      expect(response).to redirect_to root_url
      expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
    end

    context 'with permissions' do
      before do
        role = create(:'account_service/role', permissions: %w[course.content.access course.content.edit])
        create(:'account_service/grant', principal: user, role:)

        Stub.request(
          :course, :get, "/items/#{item.id}"
        ).to_return Stub.json(item_resource)
        delete_item_stub
      end

      shared_examples 'a monolithized content item' do |content_class|
        before do
          # We need to delete the item manually here, as the delete
          # request is only stubbed, but the content record's
          # destruction is impossible without. As the node is created by
          # the item factory and is dependent on the item, it have to be
          # deleted as well. Once, `xi-quiz` is part of the monolith, we
          # can destroy the `CourseService::Item` record in `xi-web`, which
          # also triggers the destruction of the content.
          CourseService::Structure::Item.where(item_id: item.id).delete_all
          item.delete
        end

        it 'redirects to the edit page' do
          expect(action).to redirect_to course_sections_path
        end

        it 'destroys the related content record' do
          expect { action }.to change(content_class, :count).from(1).to(0)
        end

        it 'deletes the item' do
          action
          expect(delete_item_stub).to have_been_requested
        end
      end

      context 'with a Lti::Exercise as item content' do
        let(:item) { create(:item, :lti_exercise) }
        let(:item_resource) { build(:'course:item', :lti_exercise, id: item.id, content_id: item.content_id) }

        it_behaves_like 'a monolithized content item', Lti::Exercise
      end

      context 'with a Video::Video as item content' do
        let(:item_resource) { build(:'course:item', :video, id: item.id, content_id: video.id, open_mode: false) }
        let(:item) { create(:item, content: video) }
        let(:video) { create(:video) }

        it_behaves_like 'a monolithized content item', Video::Video
      end

      context 'with a CourseService::Richtext as item content' do
        let(:richtext) { create(:richtext, course_id: course.id) }
        let(:item_resource) { build(:'course:item', id: item.id, content_id: richtext.id, section_id: section['id'], content_type: 'rich_text') }
        let(:item) { create(:item, content_id: richtext.id, content_type: 'rich_text') }

        it_behaves_like 'a monolithized content item', CourseService::Richtext
      end

      context 'with a quiz as item content' do
        let(:quiz) { create(:'quiz_service/quiz') }
        let(:item) { create(:item, content_id: quiz.id, content_type: 'quiz') }
        let(:item_resource) do
          build(:'course:item',
            id: item.id,
            content_id: quiz.id,
            section_id: section['id'],
            content_type: 'quiz')
        end
        let(:content_delete_stub) do
          Stub.request(:quiz, :delete, "/quizzes/#{quiz.id}")
            .to_return Stub.response(status: 200)
        end

        before do
          content_delete_stub
        end

        it 'redirects to the edit page' do
          expect(action).to redirect_to course_sections_path
        end

        it 'requests to delete the quiz' do
          action
          expect(content_delete_stub).to have_been_requested
        end

        it 'deletes the item' do
          action
          expect(delete_item_stub).to have_been_requested
        end
      end
    end
  end
end
