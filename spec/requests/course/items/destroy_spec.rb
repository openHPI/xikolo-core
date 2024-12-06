# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Destroy', type: :request do
  subject(:action) do
    delete("/courses/#{course.course_code}/sections/#{section['id']}/items/#{item.id}",
      headers:)
  end

  let(:course) { create(:course, course_code: 'example') }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:section) { build(:'course:section', course_id: course.id) }
  let(:item) { create(:item) }
  let(:item_resource) { build(:'course:item', id: item.id) }
  let(:params) { {} }
  let(:headers) { {} }
  let(:permissions) { {} }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects to login page' do
      action
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'for a logged in user' do
    let(:user_id) { generate(:user_id) }
    let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:delete_item_stub) { Stub.request(:course, :delete, "/items/#{item.id}").to_return(status: 200) }

    before { stub_user_request(id: user_id, permissions:) }

    it 'is forbidden without proper permissions' do
      action
      expect(response).to redirect_to root_url
      expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
    end

    context 'with permissions' do
      let(:permissions) { %w[course.content.access course.content.edit] }

      before do
        Stub.request(
          :course, :get, "/items/#{item.id}"
        ).to_return Stub.json(item_resource)
        Stub.request(
          :course, :get, '/enrollments',
          query: {course_id: course.id, user_id:}
        ).to_return Stub.json([])
        Stub.request(
          :course, :get, '/next_dates',
          query: hash_including(course_id: course.id)
        ).to_return Stub.json([])
        Stub.request(
          :course, :get, '/items',
          query: hash_including(section_id: section['id'])
        ).to_return Stub.json([])
        Stub.request(
          :course, :get, '/sections',
          query: {course_id: course.id}
        ).to_return Stub.json([section])
        Stub.request(
          :course, :get, "/sections/#{section['id']}"
        ).to_return Stub.json([section])
        delete_item_stub
      end

      shared_examples 'a monolithized content item' do |content_class|
        before do
          # We need to delete the item manually here, as the delete request is only stubbed,
          # but the content record's destruction is impossible without.
          # As the node is created by the item factory and is dependent on the item, it have to be deleted as well.
          # Once, `xi-quiz` and `xi-peerassessment` are part of the monolith,
          # we can destroy the `Course::Item` record in `xi-web`, which also triggers
          # the destruction of the content.
          item.node.destroy
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

      context 'with a Course::Richtext as item content' do
        let(:richtext) { create(:richtext, course_id: course.id) }
        let(:item_resource) { build(:'course:item', id: item.id, content_id: richtext.id, section_id: section['id'], content_type: 'rich_text') }
        let(:item) { create(:item, content_id: richtext.id, content_type: 'rich_text') }

        it_behaves_like 'a monolithized content item', Course::Richtext
      end

      context 'with a peer assessment as item content' do
        let(:peer_assessment_resource) { build(:'peerassessment:peerassessment', course_id: course.id) }
        let(:item) { create(:item, content_id: peer_assessment_resource['id'], content_type: 'peer_assessment') }
        let(:item_resource) do
          build(:'course:item',
            id: item.id,
            content_id: peer_assessment_resource['id'],
            section_id: section['id'],
            content_type: 'peer_assessment')
        end
        let(:content_delete_stub) do
          Stub.request(:peerassessment, :delete, "/peer_assessments/#{peer_assessment_resource['id']}")
            .to_return Stub.response(status: 200)
        end

        before do
          Stub.service(:peerassessment, build(:'peerassessment:root'))
          Stub.request(
            :peerassessment, :get, "/peer_assessments/#{peer_assessment_resource['id']}",
            query: {course_id: course['id']}
          ).to_return Stub.json([peer_assessment_resource])
          content_delete_stub
        end

        it 'redirects to the edit page' do
          expect(action).to redirect_to course_sections_path
        end

        # We do not destroy PeerAssessments upon item destruction (yet)
        # it 'destroys the related content record' do
        #   expect { action }.to change(PeerAssessment::PeerAssessment, :count).from(1).to(0)
        # end
        it 'does not request to delete the peer assessment' do
          action
          expect(content_delete_stub).not_to have_been_requested
        end

        it 'deletes the item' do
          action
          expect(delete_item_stub).to have_been_requested
        end
      end

      context 'with a quiz as item content' do
        let(:quiz_resource) { build(:'quiz:quiz') }
        let(:item) { create(:item, content_id: quiz_resource['id'], content_type: 'quiz') }
        let(:item_resource) do
          build(:'course:item',
            id: item.id,
            content_id: quiz_resource['id'],
            section_id: section['id'],
            content_type: 'quiz')
        end
        let(:content_delete_stub) do
          Stub.request(:quiz, :delete, "/quizzes/#{quiz_resource['id']}")
            .to_return Stub.response(status: 200)
        end

        before do
          Stub.service(:quiz, build(:'quiz:root'))
          Stub.request(:quiz, :get, "/quizzes/#{quiz_resource['id']}")
            .to_return Stub.json(quiz_resource)
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
