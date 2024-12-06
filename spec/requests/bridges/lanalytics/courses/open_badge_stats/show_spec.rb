# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Lanalytics Bridge API: Courses: Open Badge Stats: Show', type: :request do
  subject(:show_stats) do
    get "/bridges/lanalytics/courses/#{course_id}/open_badge_stats", headers:
  end

  let(:course_id) { course.id }
  let(:course) { create(:course, records_released: true) }
  let(:template) { create(:open_badge_template, :full, course:) }

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

  context 'for a course with Open Badges' do
    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(
        :course, :get, '/enrollments',
        query: hash_including(deleted: 'true', learning_evaluation: 'true')
      ).to_return(
        Stub.json(
          build_list(
            :'course:enrollment', 1, :with_learning_evaluation,
            completed_at: '2001-02-03'
          )
        )
      )

      create_list(:open_badge, 10, open_badge_template: template)
      # Badges for other courses should no be counted
      create_list(:open_badge, 5)
    end

    it 'shows the correct badge count' do
      show_stats

      expect(json).to eq({
        'badges_issued' => 10,
      })
    end

    context 'for a course that is not known' do
      let(:course_id) { generate(:uuid) }

      it 'does not count any badges' do
        show_stats

        expect(json).to eq({
          'badges_issued' => 0,
        })
      end
    end
  end
end
