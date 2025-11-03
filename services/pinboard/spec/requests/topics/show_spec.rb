# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topics: Show', type: :request do
  subject(:resource) { service.rel(:topic).get(params).value! }

  let(:service) { Restify.new(:test).get.value! }

  let(:params) { {id: post_id} }
  let(:post_id) { question.id }

  let!(:question) { create(:'pinboard_service/question', text:) }
  let(:text) { 'Question??' }
  let!(:answer1) { create(:'pinboard_service/answer', question:, text: 'Answer!') }
  let!(:answer2) { create(:'pinboard_service/answer', question:, text: 'Another answer!') }
  let!(:question_comment) { create(:'pinboard_service/comment', commentable: question, text: 'Commenting question.') }
  let!(:answer1_comment) { create(:'pinboard_service/comment', :for_answer, commentable: answer1, text: 'Commenting answer.') }

  it { is_expected.to respond_with :ok }

  describe '(json)' do
    it {
      expect(resource).to include(
        'id', 'title', 'abstract', 'tags', 'closed', 'num_replies', 'meta',
        'created_at'
      )
    }

    it { is_expected.to have_rel :self }
    it { is_expected.not_to include 'posts' }

    describe '[abstract]' do
      subject(:abstract) { resource['abstract'] }

      context 'with a short text' do
        let(:text) { 'super short text' }

        it 'contains the entire text' do
          expect(abstract).to eq 'super short text'
        end
      end

      context 'with a longer text' do
        let(:text) do
          <<-TEXT.strip
            Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et
            dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores.
          TEXT
        end

        before { expect(text.length).to be > 180 }

        it 'is truncated to at most 150 characters' do
          expect(abstract.length).to be <= 150
        end

        it 'is a snippet from the beginning of the original text' do
          expect(abstract).to start_with text[0, 100]
        end
      end
    end

    describe '[num_replies]' do
      subject(:num_replies) { resource['num_replies'] }

      it 'includes all replies (all answers and comments)' do
        expect(num_replies).to eq(4)
      end
    end

    describe '[meta]' do
      subject(:meta) { resource['meta'] }

      it { is_expected.to eq({}) }

      context 'when the question has a video timestamp' do
        let(:question) { create(:'pinboard_service/video_question', video_timestamp: 4444) }

        it 'exposes the video timestamp as a meta field' do
          expect(meta).to eq('video_timestamp' => 4444)
        end
      end
    end

    context 'with embed=posts' do
      let(:params) { super().merge(embed: 'posts') }

      it { is_expected.to include 'posts' }

      describe '[posts]' do
        subject(:posts) { resource['posts'] }

        it { is_expected.to have(5).items }

        it 'presents all of the topic\'s posts, whatever their type, in chronological order' do
          expect(posts[0].to_hash).to include(
            'id' => question.id,
            'author_id' => question.user_id,
            'created_at' => question.created_at.iso8601(3),
            'text' => 'Question??',
            'blocked' => false,
            'upvotes' => 0
          )
          expect(posts[1].to_hash).to include(
            'id' => answer1.id,
            'author_id' => answer1.user_id,
            'created_at' => answer1.created_at.iso8601(3),
            'text' => 'Answer!',
            'blocked' => false,
            'upvotes' => 0,
            'downvotes' => 0
          )
          expect(posts[2].to_hash).to include(
            'id' => answer2.id,
            'author_id' => answer2.user_id,
            'created_at' => answer2.created_at.iso8601(3),
            'text' => 'Another answer!',
            'blocked' => false,
            'upvotes' => 0,
            'downvotes' => 0
          )
          expect(posts[3].to_hash).to include(
            'id' => question_comment.id,
            'author_id' => question_comment.user_id,
            'created_at' => question_comment.created_at.iso8601(3),
            'text' => 'Commenting question.',
            'blocked' => false,
            'upvotes' => 0,
            'downvotes' => 0
          )
          expect(posts[4].to_hash).to include(
            'id' => answer1_comment.id,
            'author_id' => answer1_comment.user_id,
            'created_at' => answer1_comment.created_at.iso8601(3),
            'text' => 'Commenting answer.',
            'blocked' => false,
            'upvotes' => 0,
            'downvotes' => 0
          )
        end
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
