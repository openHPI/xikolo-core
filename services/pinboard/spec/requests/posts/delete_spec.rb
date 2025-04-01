# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Posts: Delete', type: :request do
  subject(:deletion) { post_resource.rel(:self).delete.value! }

  let(:service) { Restify.new(:test).get.value! }

  let(:post_resource) { service.rel(:post).get({id: post_id}).value! }

  let!(:question) { create(:question) }
  let!(:answer) { create(:answer) }
  let!(:comment) { create(:comment) }

  context 'with question ID' do
    let(:post_id) { question.id }

    it { is_expected.to respond_with :no_content }

    it 'deletes the question' do
      expect { deletion }.to change(Question, :count).from(3).to(2)
    end
  end

  context 'with answer ID' do
    let(:post_id) { answer.id }

    it { is_expected.to respond_with :no_content }

    it 'deletes the answer' do
      expect { deletion }.to change(Answer, :count).from(1).to(0)
    end
  end

  context 'with comment ID' do
    let(:post_id) { comment.id }

    it { is_expected.to respond_with :no_content }

    it 'deletes the comment' do
      expect { deletion }.to change(Comment, :count).from(1).to(0)
    end
  end

  context 'with non-existing ID' do
    let(:post_id) { '7cf36b03-587f-4f56-af8f-be8d9e3ec302' }

    it 'responds with 404 Not Found' do
      expect { deletion }.to raise_error(Restify::ClientError) do |err|
        expect(err.code).to eq 404
      end
    end
  end
end
