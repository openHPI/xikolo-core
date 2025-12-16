# frozen_string_literal: true

require 'spec_helper'

describe 'Enrollment: Reactivations: Create', type: :request do
  subject(:request) { enrollment.rel(:reactivations).post(data).value! }

  let(:api)        { Restify.new(course_service.root_url).get.value! }
  let(:enrollment) { api.rel(:enrollment).get({id: record}).value! }

  let(:submission_date) { 4.weeks.from_now }
  let(:record) { create(:'course_service/enrollment') }
  let(:data) { {submission_date: submission_date.iso8601} }

  let!(:patch_feature_flipper) do
    Stub.request(
      :account, :patch, "/users/#{record.user_id}/features",
      query: {context: record.course.context_id}
    ).to_return Stub.json({
      'course.reactivated' => 'true',
    })
  end

  let!(:unlock_graded_assignments) do
    Stub.request(
      :quiz, :post, '/user_quiz_attempts',
      body: {user_id: enrollment['user_id'], course_id: enrollment['course_id']}
    )
  end

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(
      :account, :get, "/users/#{record.user_id}"
    ).to_return Stub.json({
      features_url: "/account_service/users/#{record.user_id}/features",
    })

    Stub.service(:quiz, build(:'quiz:root'))
  end

  it 'responds with 201 Created' do
    expect(request).to respond_with :created
  end

  it 'sets forced_submission_date on record' do
    expect { request }.to change {
      record.reload.forced_submission_date.try :iso8601
    }.from(nil).to submission_date.iso8601
  end

  it 'creates a feature flipper for the user' do
    request
    expect(patch_feature_flipper).to have_been_requested
  end

  it 'unlocks all graded assignments' do
    request
    expect(unlock_graded_assignments).to have_been_requested
  end

  context 'with running reactivation' do
    before { record.update! forced_submission_date: 2.weeks.from_now }

    it 'responds with error' do
      expect { request }.to raise_error(Restify::ClientError) do |e|
        expect(e.status).to eq :unprocessable_content
        expect(e.errors).to eq 'submission_date' => 'running'
      end
    end

    context 'with explicit extend' do
      let(:data) { super().merge extend: true }

      it 'responds with 201 Created' do
        expect(request).to respond_with :created
      end

      it 'sets forced_submission_date on record' do
        expect { request }.to change {
          record.reload.forced_submission_date.try :iso8601
        }.to submission_date.iso8601
      end
    end
  end

  context 'with invalid submission date' do
    let(:data) { super().merge submission_date: '' }

    it 'responds with error' do
      expect { request }.to raise_error(Restify::ClientError) do |e|
        expect(e.status).to eq :unprocessable_content
        expect(e.errors).to eq 'submission_date' => 'invalid'
      end
    end
  end

  context 'with existing fixed learning evaluation' do
    before do
      create(
        :'course_service/fixed_learning_evaluation',
        user_id: enrollment['user_id'],
        course_id: enrollment['course_id']
      )
    end

    it 'removes the fixed learning evaluation' do
      expect { request }.to change(CourseService::FixedLearningEvaluation, :count).from(1).to 0
    end
  end
end
