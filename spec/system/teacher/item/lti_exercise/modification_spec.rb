# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Teacher: Item: LTI Exercise: Modify Item', type: :system do
  let(:user_id) { generate(:user_id) }

  let(:course) { build(:'course:course', course_code: 'the_course') }
  let(:section) { build(:'course:section', course_id: course['id'], title: 'Week 1') }
  let(:exercise) { create(:lti_exercise, provider: create(:lti_provider, :global)) }
  let(:item) { build(:'course:item', :lti_exercise, item_params) }
  let(:item_params) do
    {
      course_id: course['id'],
      section_id: section['id'],
      content_id: exercise['id'],
      title: 'Awesome LTI exercise',
    }
  end

  before do
    stub_user id: user_id, permissions: %w[course.content.access course.content.edit]

    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course)
    Stub.request(:course, :get, '/enrollments', query: {course_id: course['id'], user_id:})
      .to_return Stub.json([{}])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, '/sections', query: {course_id: course['id']})
      .to_return Stub.json([section])
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(:course, :get, '/items', query: hash_including(section_id: section['id']))
      .to_return Stub.json([item])
    Stub.request(:course, :get, "/items/#{item['id']}", query: hash_including({}))
      .to_return Stub.json(item)
    Stub.request(:course, :put, "/items/#{item['id']}", body: hash_including(id: item['id']))
      .to_return Stub.json(item)

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json({id: user_id})
  end

  context 'error handling' do
    context 'for a validation error' do
      it 'displays an error inline' do
        visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
        fill_markdown_editor 'Instructions', with: 's3://invalid'
        click_on 'Save item'

        expect(page).to have_content('Referencing unknown files is not allowed')
      end
    end
  end

  context 'with valid attributes' do
    it 'displays a success flash message' do
      visit "/courses/the_course/sections/#{section['id']}/items/#{item['id']}/edit"
      fill_markdown_editor 'Instructions', with: 'New instructions'
      click_on 'Save item'

      expect(page).to have_css('[role="status"]', text: 'The item was updated successfully.')
    end
  end
end
