# frozen_string_literal: true

require 'spec_helper'

describe AnswerDecorator, type: :decorator do
  let(:answer) { create(:'pinboard_service/answer') }
  let(:decorator) { AnswerDecorator.new(answer) }

  describe '#api_v1' do
    subject { json }

    let(:json) { decorator.as_json.stringify_keys }

    context 'attachment_url' do
      let(:answer) { create(:'pinboard_service/answer', attachment_uri: 's3://xikolo-pinboard/courses/3/thread/2/1/hans.jpg') }

      it 'returns a public S3 URL' do
        expect(json['attachment_url']).to eq 'https://s3.xikolo.de/xikolo-pinboard/courses/3/thread/2/1/hans.jpg'
      end
    end
  end

  describe '#to_event' do
    subject(:json) { decorator.to_event.stringify_keys }

    it 'includes the correct keys' do
      expect(json).to include('id')
      expect(json).to include('text')
      expect(json).to include('user_id')
      expect(json).to include('course_id')
      expect(json).to include('unhelpful_answer_score')
      expect(json).to include('ranking')
      expect(json).to include('abuse_report_state')
      expect(json).to include('abuse_report_count')
      expect(json).to include('attachment_url')
    end

    it 'does includes certain keys' do
      expect(json).not_to include('blocked')
      expect(json).not_to include('reviewed')
    end

    describe "['course_id']" do
      subject(:course_id) { json['course_id'] }

      it 'contains the course id' do
        expect(course_id).to be answer.question.course_id
      end
    end

    describe "['technical']" do
      subject(:technical) { json['technical'] }

      it 'returns false' do
        expect(technical).to be false
      end
    end

    context 'for technical question' do
      let(:answer) { create(:'pinboard_service/technical_answer') }

      describe "['technical']" do
        subject(:technical) { json['technical'] }

        it 'returns true' do
          expect(technical).to be true
        end
      end
    end
  end

  describe 'text with embedded files' do
    subject(:json) { decorator.as_json.stringify_keys }

    let(:decorator) { described_class.new answer, context: }
    let(:context) { {} }
    let(:file_uri) { 's3://xikolo-pinboard/courses/1L0csnOIXZC1Un4Jct5Yuz/topics/Ur0skV1C03TKK3gqx1Izc/1iGR3qxnxA4tzlQzF34UDd/file.jpg' }
    let(:file_url) { Xikolo::S3.object(file_uri).public_url }
    let(:text_with_uri) { "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri}" }
    let(:text_with_url) { "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{file_url}" }
    let!(:answer) { create(:'pinboard_service/answer', text: text_with_uri) }

    context 'when the post is only shown' do
      it 'returns the text having the uris converted to public urls' do
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

      it 'returns the text split into markup and urls' do
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
