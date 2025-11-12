# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Commentable::Store, type: :operation do
  subject(:store) { described_class.new(question, attributes).call }

  context 'updating a post with a file reference in the text' do
    let(:file_uri) do
      's3://xikolo-pinboard/courses/1L0csnOIXZC1Un4Jct5Yuz/topics/Ur0skV1C03TKK3gqx1Izc/1iGR3qxnxA4tzlQzF34UDd/file.jpg'
    end
    let(:text) { "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri}" }
    let(:question) { create(:'pinboard_service/question', text:) }
    let(:attributes) { {} }
    let!(:delete_stub) do
      stub_request(
        :delete, %r{https://s3.xikolo.de/xikolo-pinboard/courses/[a-zA-Z0-9]+/topics/[a-zA-Z0-9]+/[a-zA-Z0-9]+/file.jpg}
      ).with(
        headers: {'Host' => 's3.xikolo.de'}
      ).to_return(status: 200, body: '<xml></xml>')
    end

    context 'when changing the text but not the referenced file' do
      let(:attributes) do
        super().merge(text: "![A nice file description][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri} and some more text")
      end

      it 'does not delete the referenced file from S3' do
        store
        expect(delete_stub).not_to have_been_requested
      end
    end

    context 'when removing the file reference from the text' do
      let(:attributes) { super().merge(text: 'foo') }

      it 'deletes the file (no longer referenced) from S3' do
        store
        expect(delete_stub).to have_been_requested
      end
    end

    context 'when blocking a question' do
      let(:attributes) { super().merge(text:, workflow_state: 'blocked') }

      it 'does not delete the referenced file from S3' do
        store
        expect(delete_stub).not_to have_been_requested
      end

      it 'does not change the text' do
        expect { store }.not_to change(question, :text)
      end
    end

    context 'when unblocking a question' do
      let(:attributes) { super().merge(text:, workflow_state: 'reviewed') }

      it 'does not delete the referenced file from S3' do
        store
        expect(delete_stub).not_to have_been_requested
      end

      it 'does not change the text' do
        expect { store }.not_to change(question, :text)
      end
    end

    context 'when replacing the file with a new one' do
      let(:upload_id) { 'b5f99337-224f-40f5-aa82-44ee8b272579' }
      let(:filename) { 'new_file.jpg' }
      let(:new_file_uri) { "upload://#{upload_id}/#{filename}" }
      let(:attributes) do
        super().merge(text: "![enter file description here][1]A text with file\r\n\r\n\r\n  [1]: #{new_file_uri}")
      end

      let(:cid) { UUID4(question.course_id).to_str(format: :base62) }
      let(:qid) { UUID4(question.id).to_str(format: :base62) }
      let(:store_regex) { %r{https://s3.xikolo.de/xikolo-pinboard/courses/#{cid}/topics/#{qid}/[0-9a-zA-Z]+/#{filename}}x }
      let(:upload_stub) do
        stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
          .and_return(status: 200, body: '<xml></xml>')
      end

      before do
        stub_request(:head, "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{filename}")
          .and_return(
            status: 200,
            headers: {
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        stub_request(:head, store_regex).and_return(status: 404)
        upload_stub
      end

      it 'deletes the file (outdated) from S3' do
        store
        expect(delete_stub).to have_been_requested
      end

      it 'updates the text and the file reference' do
        expect { store }.to change(question, :text)
          .from(text)
          .to(match %r{s3://xikolo-pinboard/courses/#{cid}+/topics/#{qid}+/[a-zA-Z0-9]+/new_file.jpg})
      end

      context 'when the referenced file has the same name' do
        let(:filename) { 'file.jpg' }

        it 'deletes the file (outdated) from S3' do
          store
          expect(delete_stub).to have_been_requested
        end

        it 'updates the file reference' do
          expect { store }.to change(question, :text)
        end
      end

      context 'when adding a second file reference' do
        let(:attributes) do
          super().merge(
            text: "![A nice file description][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri}" + " ![enter file description here][2]A text with file\r\n\r\n\r\n  [2]: #{new_file_uri}"
          )
        end

        it 'does not delete the referenced file from S3' do
          store
          expect(delete_stub).not_to have_been_requested
        end

        it 'uploads the new file' do
          store
          expect(upload_stub).to have_been_requested
        end

        context 'when the new file references in the text are a subset of the existing references' do
          let(:attributes) do
            super().merge(
              text: "![A nice file description][1]A text with file\r\n\r\n\r\n  [1]: #{file_uri}" + " ![enter file description here][2]A text with file\r\n\r\n\r\n  [2]: #{file_uri}"
            )
          end

          it 'does not delete the referenced file from S3' do
            expect(delete_stub).not_to have_been_requested
          end

          it 'does not re-upload the file' do
            expect(upload_stub).not_to have_been_requested
          end
        end
      end
    end
  end
end
