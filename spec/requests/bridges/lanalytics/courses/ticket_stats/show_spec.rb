# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Lanalytics Bridge API: Courses: Ticket Stats: Show', type: :request do
  subject(:show_stats) do
    get "/bridges/lanalytics/courses/#{course_id}/ticket_stats", headers:
  end

  let(:course_id) { course.id }
  let(:course) { create(:course, :active) }
  let(:token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      show_stats

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'for a course with tickets' do
    before do
      create_list(:ticket, 2, course_id: course.id)
      create_list(:ticket, 3, :today, course_id: course.id)

      # Some tickets for other courses that should not be part of the aggregation
      create(:ticket, course_id: generate(:course_id))
      create(:ticket, :today, course_id: generate(:course_id))
    end

    it 'correctly aggregates ticket stats' do
      show_stats

      expect(json).to eq({
        'ticket_count' => 5,
        'ticket_count_last_day' => 3,
      })
    end

    context 'for a course that is not known' do
      let(:course_id) { generate(:uuid) }

      it 'has no tickets to count' do
        show_stats

        expect(json).to eq({
          'ticket_count' => 0,
          'ticket_count_last_day' => 0,
        })
      end
    end
  end
end
