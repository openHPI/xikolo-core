# frozen_string_literal: true

require 'spec_helper'

describe 'Metrics API', type: :request do
  it 'renders all available metrics' do
    get '/metrics', params: {available: true}
    expect(json.pluck('name')).to match_array %w[
      AvgSessionDuration
      CoursePoints
      Sessions
      TotalSessionDuration
      CourseActivity
      PinboardActivity
      PinboardPostingActivity
      PinboardWatchCount
      QuestionResponseTime
      UserEnrollmentCount
      VideoPlayerNavigationCount
      VideoPlayerSeekCount
      VideoVisitCount
      VisitCount
    ]
  end
end
