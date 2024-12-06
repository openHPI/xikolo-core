# frozen_string_literal: true

require 'spec_helper'

describe QuestionDecorator, type: :decorator do
  let(:question) { create(:question) }
  let(:decorator) { described_class.new question }

  describe '#api_v1' do
    subject { json }

    let(:json) { decorator.as_json.stringify_keys }

    describe "['id']" do
      subject { super()['id'] }

      it { is_expected.to be question.id }
    end

    it { is_expected.not_to be_has_key 'answer_count' }
    it { is_expected.to include 'user_tags' }
    it { is_expected.to include 'views' }
    it { is_expected.to include 'sticky' }
    it { is_expected.to include 'deleted' }
    it { is_expected.not_to include('blocked') }
    it { is_expected.not_to include('reviewed') }
    it { is_expected.to include('abuse_report_state') }
    it { is_expected.to include('abuse_report_count') }
    it { is_expected.to include('attachment_url') }

    context 'attachment_url' do
      let(:question) { create(:question, attachment_uri: 's3://xikolo-pinboard/courses/3/thread/2/1/hans.jpg') }

      it 'returns a public S3 URL' do
        expect(json['attachment_url']).to eq 'https://s3.xikolo.de/xikolo-pinboard/courses/3/thread/2/1/hans.jpg'
      end
    end

    context 'within a collection' do
      let(:decorator) { described_class.new question, context: {collection: true} }

      describe "['answer_count']" do
        subject { super()['answer_count'] }

        it { is_expected.to eq 0 }
      end

      it { is_expected.to include 'answer_comment_count' }

      context 'with answers' do
        let!(:answer) { create(:answer, question:) }

        describe "['answer_count']" do
          subject { super()['answer_count'] }

          it { is_expected.to eq 1 }
        end

        context 'with answer_comments' do
          before do
            create(:comment, :for_answer, commentable: answer)
            create(:comment, :for_answer, commentable: answer, deleted: true)
          end

          describe "['answer_comment_count']" do
            subject { super()['answer_comment_count'] }

            it { is_expected.to eq 1 }
          end
        end
      end

      context 'with comments' do
        before do
          create(:comment, commentable: question)
          create(:comment, commentable: question, deleted: true)
        end

        describe "['comment_count']" do
          subject { super()['comment_count'] }

          it { is_expected.to eq 1 }
        end
      end

      context 'with user tags' do
        let(:question) { create(:question_with_tags) }

        describe "['user_tags']" do
          subject(:user_tags) { json['user_tags'] }

          let(:tag1) { question.tags.first }
          let(:tag2) { question.tags.last }

          it 'lists the ids and names of related user tags' do
            expect(user_tags).to match_array [{'id' => tag1.id, 'name' => 'SQL'}, {'id' => tag2.id, 'name' => 'Definition'}] # rubocop:disable RSpec/MatchArray
          end
        end
      end
    end

    context 'with user read state' do
      it { is_expected.not_to include 'read' }

      context 'with user_watch context' do
        let(:decorator) { described_class.new question, context: {user_watch: true} }

        it { is_expected.to include 'read' }
      end
    end
  end

  describe '#to_event' do
    subject { json }

    let(:json) { decorator.to_event.stringify_keys }

    describe "['id']" do
      subject { super()['id'] }

      it { is_expected.to be question.id }
    end

    it { is_expected.to include 'user_id' }
    it { is_expected.to include 'course_id' }
    it { is_expected.to include 'technical' }
    it { is_expected.not_to be_has_key 'answer_count' }
    it { is_expected.to include 'user_tags' }
    it { is_expected.to include 'views' }
    it { is_expected.to include 'sticky' }
    it { is_expected.to include 'deleted' }
    it { is_expected.not_to include('blocked') }
    it { is_expected.not_to include('reviewed') }
    it { is_expected.to include('abuse_report_state') }
    it { is_expected.to include('abuse_report_count') }
    it { is_expected.to include('attachment_url') }

    describe "['technical']" do
      subject { super()['technical'] }

      it { is_expected.to be false }
    end

    context 'for technical question' do
      let(:question) { create(:technical_question) }

      describe "['technical']" do
        subject { super()['technical'] }

        it { is_expected.to be true }
      end
    end

    context 'with accepted answer' do
      let(:question) { create(:question_with_accepted_answer) }

      it { is_expected.to include('accepted_answer_user_id') }
    end

    describe 'text with embedded files' do
      subject(:json) { decorator.as_json.stringify_keys }

      let(:decorator) { described_class.new question, context: }
      let(:context) { {} }
      let(:file_uri) { 's3://xikolo-pinboard/courses/1L0csnOIXZC1Un4Jct5Yuz/topics/Ur0skV1C03TKK3gqx1Izc/1iGR3qxnxA4tzlQzF34UDd/file.jpg' }
      let(:file_url) { Xikolo::S3.object(file_uri).public_url }
      let(:text_with_uri) { "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri}" }
      let(:text_with_url) { "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{file_url}" }
      let!(:question) { create(:question, text: text_with_uri) }

      context 'when the post is only shown' do
        it 'returns the text having the URIs converted to public URLs' do
          expect(json['text']).to eq text_with_url
        end
      end

      context 'when the post is blocked or unblocked' do
        let(:context) { super().merge(text_purpose: 'display') }

        it 'returns the text containing URIs' do
          expect(json['text']).to eq text_with_uri
        end
      end

      context 'when the post has input data' do
        let(:context) { super().merge(text_purpose: 'input') }

        it 'returns the text split into markup and URLs' do
          expect(json['text']).to match hash_including(
            'markup' => "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: s3://xikolo-pinboard/courses/1L0csnOIXZC1Un4Jct5Yuz/topics/Ur0skV1C03TKK3gqx1Izc/1iGR3qxnxA4tzlQzF34UDd/file.jpg",
            'other_files' => {
              file_uri => 'file.jpg',
            },
            'url_mapping' => {file_uri => file_url}
          )
        end
      end
    end
  end
end
