# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Posts: Show', type: :request do
  subject(:resource) { service.rel(:post).get({id: post_id}).value! }

  let(:service) { Restify.new(pinboard_service_url).get.value! }

  let!(:question) { create(:'pinboard_service/question') }
  let!(:answer) { create(:'pinboard_service/answer') }
  let!(:comment) { create(:'pinboard_service/comment') }

  context 'with question ID' do
    let(:post_id) { question.id }

    it { is_expected.to respond_with :ok }

    describe '(json)' do
      it { is_expected.to include 'id' }
      it { is_expected.to include 'upvotes' }
      it { is_expected.to have_rel :self }
      it { is_expected.to have_rel :reports }
      it { is_expected.to have_rel :user_votes }
    end
  end

  context 'with answer ID' do
    let(:post_id) { answer.id }

    it { is_expected.to respond_with :ok }

    describe '(json)' do
      it { is_expected.to include 'id' }
      it { is_expected.to include 'upvotes' }
      it { is_expected.to include 'downvotes' }
      it { is_expected.to have_rel :self }
      it { is_expected.to have_rel :reports }
      it { is_expected.to have_rel :user_votes }
    end
  end

  context 'with comment ID' do
    let(:post_id) { comment.id }

    it { is_expected.to respond_with :ok }

    describe '(json)' do
      it { is_expected.to include 'id' }
      it { is_expected.to include 'upvotes' }
      it { is_expected.to include 'downvotes' }
      it { is_expected.to have_rel :self }
      it { is_expected.to have_rel :reports }
      it { is_expected.to have_rel :user_votes }
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
