# frozen_string_literal: true

require 'spec_helper'

describe 'Documents: Update', type: :request do
  subject(:action) { api.rel(:document).patch(data, params: {id: document.id}).value! }

  let!(:document) { create(:'course_service/document', :with_localizations) }
  let!(:course) { create(:'course_service/course', :full_blown) }

  let(:api) { restify_with_headers(course_service.root_url).get.value }

  let(:data) do
    {
      title: 'Updated title',
      tags: ['new_tag'],
      item_ids: [course.items.first.id],
    }
  end

  it 'responds with :no_content' do
    expect(action).to respond_with :no_content
  end

  it 'changes the title' do
    expect { action }.to change { document.reload.title }.to 'Updated title'
  end

  it 'replaces the tags' do
    expect { action }.to change { document.reload.tags }.to ['new_tag']
  end

  it 'updates the courses list' do
    expect { action }.to change { document.reload.courses.map(&:id) }.to [course.id]
  end
end
