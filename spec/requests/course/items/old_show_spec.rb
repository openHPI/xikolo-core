# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Show', type: :request do
  subject(:show_item) { get "/courses/example/items/#{item.id}", headers: }

  let(:headers) { {} }
  let(:user_id) { generate(:user_id) }
  let(:content_id) { generate(:uuid) }
  let(:course) { create(:course, course_code: 'example') }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { create(:item, section: section, content: richtext) }
  let(:item_resource) { build(:'course:item', id: item.id, **item_params) }
  let(:item_params) do
    {
      section_id: section.id,
      content_type: 'rich_text',
      content_id:,
      title: 'The Richtext Item',
      open_mode: false,
      published:,
    }
  end
  let(:richtext) { create(:richtext, id: content_id, course:) }
  let(:published) { true }

  before do
    Stub.request(:course, :get, '/courses/example')
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, "/items/#{item.id}",
      query: {user_id:}
    ).to_return Stub.json(item_resource)
  end

  context 'for authenticated users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.content.access.available] }
    let(:enrollments) { [] }
    let!(:visit_stub) do
      Stub.request(:course, :post, "/items/#{item.id}/users/#{user_id}/visit")
    end

    before do
      stub_user_request(id: user_id, permissions:)

      Stub.request(
        :course, :get, "/items/#{item.id}"
      ).to_return Stub.json(item_resource)

      Stub.request(
        :course, :get, '/sections',
        query: {course_id: course.id}
      ).to_return Stub.json([section_resource])

      Stub.request(
        :course, :get, "/sections/#{section.id}"
      ).to_return Stub.json(section_resource)

      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, user_id:}
      ).to_return Stub.json(enrollments)

      Stub.request(
        :account, :get, "/users/#{user_id}/preferences"
      ).to_return Stub.json({})

      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(course_id: course.id, user_id:)
      ).to_return Stub.json([])
    end

    context 'with an item prerequisite' do
      let(:required_item) { create(:item, content_type: 'rich_text') }
      let(:item_params) { super().merge required_item_ids: [required_item.id] }

      before do
        Stub.request(
          :course, :get, '/items',
          query: hash_including(section_id: section.id)
        ).to_return Stub.json([item_resource])
      end

      it 'interrupts with the requirements page' do
        show_item
        expect(response.body).to include 'Requirements not met'
        expect(response.body).to include required_item.title
      end

      it 'does not create a visit' do
        show_item
        expect(visit_stub).not_to have_been_requested
      end

      context '(requirement fulfilled)' do
        before do
          user = create(:user, id: user_id)
          create(:visit, item: required_item, user:)
        end

        it 'shows the item' do
          show_item
          expect(response.body).to include item_resource['title']
          expect(response.body).not_to include 'Requirements not met'
          expect(visit_stub).to have_been_requested
        end
      end

      context 'for graded quizzes' do
        let(:item_params) do
          super().merge(
            content_type: 'quiz',
            exercise_type: 'main',
            title: 'The exam',
            required_item_ids: [required_item.id]
          )
        end

        before do
          Stub.request(
            :quiz, :get, "/quizzes/#{content_id}"
          ).to_return Stub.json({id: content_id, current_allowed_attempts: 1})
          Stub.request(
            :quiz, :get, '/questions', query: {per_page: 250, quiz_id: content_id}
          ).to_return Stub.json([])
        end

        context 'when enrolled and there are prerequisites' do
          let(:enrollments) { [build(:'course:enrollment', course_id: course.id, user_id:)] }

          before do
            Stub.request(
              :quiz, :get, '/quiz_submissions', query: {newest_first: true, quiz_id: content_id, user_id:}
            ).to_return Stub.json([])
            Stub.request(
              :quiz, :get, '/user_quiz_attempts', query: {quiz_id: content_id, user_id:}
            ).to_return Stub.json({attempts: 1, additional_attempts: 0})
          end

          it 'interrupts with the requirements page' do
            show_item
            expect(response.body).to include 'The exam'
            expect(response.body).to include 'Requirements not met'
          end

          it 'does not show an enrollment notice' do
            show_item
            expect(response.body).to include 'The exam'
            expect(response.body).not_to include 'You are not enrolled. Please enroll to see this quiz.'
          end
        end
      end
    end
  end
end
