# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Posts: User Votes: Set', type: :request do
  subject(:resource) { post.rel(:user_votes).put(vote_data, params: {id: user_id}).value! }

  let(:service) { restify_with_headers(pinboard_service_url).get.value! }
  let(:post) { service.rel(:post).get({id: post_id}).value! }

  let(:vote_data) { {value: vote_value} }

  let!(:question) { create(:'pinboard_service/question') }
  let!(:answer) { create(:'pinboard_service/answer') }
  let!(:comment) { create(:'pinboard_service/comment') }
  let(:user_id) { SecureRandom.uuid }
  let(:vote_value) { 1 }

  context 'with question ID' do
    let(:post_id) { question.id }

    it { is_expected.to respond_with :no_content }

    it 'creates a new vote' do
      expect { resource }.to change { question.votes.count }.by(1)
    end

    context 'with existing vote' do
      let!(:vote) { PinboardService::Vote.create(user_id:, votable: question, value: -1) }

      it { is_expected.to respond_with :no_content }

      it 'does not create a new vote' do
        expect { resource }.not_to change(PinboardService::Vote, :count)
      end

      it 'updates the existing vote' do
        expect { resource }.to change { vote.reload.value }.from(-1).to(1)
      end
    end
  end

  context 'with answer ID' do
    let(:post_id) { answer.id }

    it { is_expected.to respond_with :no_content }

    it 'creates a new vote' do
      expect { resource }.to change { answer.votes.count }.by(1)
    end

    context 'with existing vote' do
      let!(:vote) { PinboardService::Vote.create(user_id:, votable: answer, value: -1) }

      it { is_expected.to respond_with :no_content }

      it 'does not create a new vote' do
        expect { resource }.not_to change(PinboardService::Vote, :count)
      end

      it 'updates the existing vote' do
        expect { resource }.to change { vote.reload.value }.from(-1).to(1)
      end
    end
  end

  context 'with comment ID' do
    let(:post_id) { comment.id }

    it { is_expected.to respond_with :no_content }

    it 'creates a new vote' do
      expect { resource }.to change { comment.votes.count }.by(1)
    end

    context 'with existing vote' do
      let!(:vote) { PinboardService::Vote.create(user_id:, votable: comment, value: -1) }

      it { is_expected.to respond_with :no_content }

      it 'does not create a new vote' do
        expect { resource }.not_to change(PinboardService::Vote, :count)
      end

      it 'updates the existing vote' do
        expect { resource }.to change { vote.reload.value }.from(-1).to(1)
      end
    end
  end

  context 'with non-existing ID' do
    let(:post_id) { '7cf36b03-587f-4f56-af8f-be8d9e3ec302' }

    it 'responds with 404 Not Found' do
      expect { resource }.to raise_error(Restify::ClientError) do |err|
        expect(err.code).to eq 404
      end
    end
  end
end
