# frozen_string_literal: true

require 'spec_helper'
require 'active_support/testing/time_helpers'

describe QuizSubmissionController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:user_uuid)   { SecureRandom.uuid }
  let(:course_id)   { SecureRandom.uuid }
  let(:section_id) { SecureRandom.uuid }
  let(:item_id)     { SecureRandom.uuid }
  let(:quiz_id)     { SecureRandom.uuid }
  let(:submission_id) { SecureRandom.uuid }
  let(:question_id) { SecureRandom.uuid }
  let(:request_context_id) { course_context_id }
  let(:permissions) { ['course.content.access.available'] }
  let(:course_context_id) { SecureRandom.uuid }
  let(:section_resource) { build(:'course:section', id: section_id, course_id: course_id) }
  let(:item_submission_deadline) { 4.days.from_now.iso8601.to_s }
  let(:quiz_access_time) { Time.zone.now.iso8601.to_s }
  let(:plain_item) do
    {
      id: item_id,
      title: 'Item title',
      position: 1,
      submission_deadline: item_submission_deadline,
      effective_start_date: 2.days.ago.iso8601,
      effective_end_date: 4.days.from_now.iso8601,
      content_type: 'quiz',
      exercise_type: 'main',
      icon_type: nil,
      proctored: false,
      course_id:,
      time_effort: 100,
      featured: true,
      published: true,
    }
  end

  before do
    Stub.service(:account, build(:'account:root'))
    stub_user id: 'user-1', display_name: 'John Smith', permissions:, features: {}

    Stub.service(:course, build(:'course:root'))
    stub_request(:get, %r{http://localhost:3000/course_service/sections/[0-9a-f\-]+})
      .to_return(
        status: 200,
        body: section_resource.to_json,
        headers: {'Content-Type' => 'application/json'}
      )
    Stub.request(
      :course, :get, "/items/#{plain_item[:id]}"
    ).to_return Stub.json(plain_item)
    Stub.request(
      :course, :get, "/items/#{plain_item[:id]}", query: {user_id: 'user-1'}
    ).to_return Stub.json(plain_item)

    Stub.request(:course, :get, '/items',
      query: {published: true, section_id: nil, state_for: 'user-1'}).to_return Stub.json([plain_item])

    Stub.request(
      :course, :get, "/sections?course_id=#{course_id}"
    ).to_return Stub.json([{
      id: section_id,
      position: 1,
      course_id:,
    }])
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      title: 'Test Course',
      description: 'A Test Course.',
      status: 'active',
      course_code: 'test',
      start_date: DateTime.new(2013, 7, 12).iso8601,
      end_date: DateTime.new(2013, 8, 19).iso8601,
      abstract: 'Test Course abstract.',
      lang: 'en',
      context_id: course_context_id,
    })

    Stub.service(:quiz, build(:'quiz:root'))

    Stub.request(:quiz, :get, '/questions',
      query: {per_page: 250, quiz_id: quiz_id}).to_return Stub.json([{
        id: question_id,
      title: 'Question Title',
      position: 1,
      quiz_id: quiz_id,
      content_type: 'quiz_question',
      time_effort: 100,
      }])
    Stub.request(:quiz, :get, "/quizzes/#{quiz_id}").to_return Stub.json({
      id: quiz_id,
      current_time_limit_seconds: 600, # 10 minutes
    })

    Stub.request(:quiz, :get, '/answers', query: {per_page: 250, question_id: question_id})
      .to_return Stub.json([])

    stub_request(:get, %r{http://localhost:3000/course_service/enrollments\?course_id=.*&user_id=user-1})
      .to_return(status: 200, body: '[]', headers: {'Content-Type' => 'application/json'})

    allow(controller).to receive(:create_visit!)
    allow(controller).to receive(:shuffle_answers)
    allow(controller).to receive(:set_page_title)
    allow(controller).to receive(:short_uuid) {|uuid| uuid[0..5] }

    allow(controller).to receive_messages(proctoring?: false, submission_in_time?: true, item: {
      'id' => item_id,
      'content_type' => 'quiz',
      'content_id' => quiz_id,
      'title' => 'Quiz',
      'submission_deadline' => item_submission_deadline,
    })

    Stub.request(:quiz, :post, '/quiz_submissions').to_return Stub.json({
      id: submission_id,
      quiz_id: quiz_id,
      quiz_access_time: quiz_access_time,
    })
  end

  describe '#new' do
    subject(:request_action) { get :new, params: {course_id:, item_id:} }

    context 'when quiz has not been started yet' do
      it 'sets @counter_end_timediff to a 10-minute duration' do
        request_action

        diff = assigns(:counter_end_timediff)
        expect(diff).to be_a(Numeric)
        expect(diff).to be_positive
        expect(diff).to be <= 10.minutes.to_i
      end
    end

    context 'when quiz started 7 minutes ago' do
      let(:quiz_access_time) { 7.minutes.ago.iso8601.to_s }

      it 'sets @counter_end_timediff to a 3-minute duration' do
        request_action
        diff = assigns(:counter_end_timediff)
        expect(diff).to be_a(Numeric)
        expect(diff).to be_positive
        expect(diff).to be <= 3.minutes.to_i
      end
    end

    context 'When there is no submission_deadline' do
      let(:item_submission_deadline) { nil }

      it 'sets @counter_end_timediff to 10.minutes.ago' do
        request_action

        diff = assigns(:counter_end_timediff)

        expect(diff).to be_a(Numeric)
        expect(diff).to be_positive
        expect(diff).to be <= 10.minutes.to_i
      end
    end
  end
end
