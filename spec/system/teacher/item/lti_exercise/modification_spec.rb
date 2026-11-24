# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Teacher: Item: LTI Exercise: Modify Item', type: :system do
  let(:user) { create(:'account_service/user') }

  let(:course) { create(:'course_service/course') }
  let(:section) { create(:'course_service/section', course:) }
  let(:exercise) { create(:lti_exercise, provider: create(:lti_provider, :global, course_id: course.id)) }
  let(:item) { create(:'course_service/item', section:, content: exercise) }

  before do
    sign_in(user:)

    admins_group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user:, group: admins_group)
  end

  context 'error handling' do
    context 'for a validation error' do
      it 'displays an error inline' do
        visit "/learn/#{course.course_code}/sections/#{section.id}/items/#{item.id}/edit"
        fill_markdown_editor 'Instructions', with: 's3://invalid'
        click_on 'Save item'

        expect(page).to have_text('Referencing unknown files is not allowed')
      end
    end
  end

  context 'with valid attributes' do
    it 'displays a success flash message' do
      visit "/learn/#{course.course_code}/sections/#{section.id}/items/#{item.id}/edit"
      fill_markdown_editor 'Instructions', with: 'New instructions'
      click_on 'Save item'

      expect(page).to have_css('[role="status"]', text: 'The item was updated successfully.')
    end
  end
end
