# frozen_string_literal: true

require 'spec_helper'

describe 'Enrollment: Reactivations: Create', type: :request do
  subject(:request) { enrollment.rel(:reactivations).post(params).value! }

  let(:api)        { Restify.new(:test).get.value! }
  let(:enrollment) { api.rel(:enrollment).get(id: record).value! }

  let(:submission_date) { 4.weeks.from_now }
  let(:record) { create(:enrollment) }
  let(:params) { {submission_date: submission_date.iso8601} }

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
      body: {user_id: enrollment.user_id, course_id: enrollment.course_id}
    )
  end

  before do
    Stub.service(
      :account,
      user_url: '/users/{id}',
      group_url: '/groups/{id}'
    )
    Stub.request(
      :account, :get, "/users/#{record.user_id}"
    ).to_return Stub.json({
      features_url: "/users/#{record.user_id}/features",
    })

    Stub.service(
      :quiz,
      user_quiz_attempts_url: '/user_quiz_attempts'
    )
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
      let(:params) { super().merge extend: true }

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
    let(:params) { super().merge submission_date: '' }

    it 'responds with error' do
      expect { request }.to raise_error(Restify::ClientError) do |e|
        expect(e.status).to eq :unprocessable_content
        expect(e.errors).to eq 'submission_date' => 'invalid'
      end
    end
  end

  context 'with existing fixed learning evaluation' do
    before do
      create(:fixed_learning_evaluation,
        user_id: enrollment.user_id,
        course_id: enrollment.course_id)
    end

    it 'removes the fixed learning evaluation' do
      expect { request }.to change(FixedLearningEvaluation, :count).from(1).to 0
    end
  end
end
