# frozen_string_literal: true

require 'spec_helper'

describe Course::Richtext::Store, type: :operation do
  subject(:store) { described_class.new(richtext, params).call }

  let(:course) { create(:course) }
  let(:upload_id) { 'ecfde9ec-d464-4574-b518-56cd8d3282a0' }
  let(:params) { {text:, course_id: course.id} }
  let(:uri_regex) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/#{file_name}}x }

  let(:read_upload_stub) do
    stub_request(:head, "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}")
      .and_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_richtext',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
  end
  let(:upload_stub) { stub_request(:put, uri_regex).and_return(status: 200, body: '<xml></xml>') }
  let(:check_target_stub) { stub_request(:head, uri_regex).and_return(status: 404) }

  describe '(creating)' do
    let(:richtext) { Course::Richtext.new }
    let(:file_name) { 'richtext_image.png' }

    context 'when creating a new richtext item' do
      context 'without reference for an uploaded file' do
        let(:text) { 'Markup description (without an image reference)' }

        it 'updates the resource' do
          expect { store }.to change(Course::Richtext, :count).from(0).to(1)
          expect(richtext.text.to_s).to eq('Markup description (without an image reference)')
        end
      end

      context 'including a reference for an uploaded file' do
        let(:text) { "Markup description\r\n\r\n![Insert image description](upload://#{upload_id}/#{file_name})" }

        before do
          read_upload_stub
          check_target_stub
          upload_stub
        end

        it 'updates the resource and uploads the file' do
          expect { store }.to change(Course::Richtext, :count).from(0).to(1)
          expect(Course::Richtext.take.text.to_s).to match(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/richtext_image.png}x)
          expect(upload_stub).to have_been_requested
        end
      end
    end
  end

  describe '(updating)' do
    let(:richtext) { create(:richtext, text: existing_text) }
    let(:file_name) { 'richtext_image.png' }

    context 'when updating an existing richtext item' do
      let(:richtext) { create(:richtext, text: existing_text) }
      let(:existing_text) { "![enter file description here] A text with file\r\n\r\n\r\n  #{existing_file_uri}" }

      context 'with a new text having the same file referenced' do
        let(:existing_file_uri) { "s3://xikolo-public/richtexts/2HdilJQuvQYPVktWuS7qrB/#{file_name}" }
        let(:text) { "![A nice file description] A text with file\r\n\r\n\r\n  #{existing_file_uri} and some more text" }

        it 'updates the text only' do
          store
          expect(richtext.text.to_s).to eq(text)
        end

        it 'does not delete the referenced file' do
          expect { store }.not_to have_enqueued_job(S3FileDeletionJob)
        end
      end

      context 'with the same text but a new file reference' do
        let(:existing_file_uri) { "s3://xikolo-public/richtexts/2HdilJQuvQYPVktWuS7qrB/#{existing_file_name}" }
        let(:existing_file_name) { 'old_file.png' }
        let(:text) { "Markup description\r\n\r\n![Insert image description](upload://#{upload_id}/#{file_name})" }
        let(:file_uri) { "s3://xikolo-public/richtexts/2HdilJQuvQYPVktWuS7qrB/#{existing_file_name}" }

        before do
          check_target_stub
          read_upload_stub
          upload_stub
        end

        it 'updates the file ref only' do
          store
          expect(richtext.text.to_s).to match(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/richtext_image.png}x)
          expect(upload_stub).to have_been_requested
        end

        it 'removes the old file' do
          expect { store }.to have_enqueued_job(S3FileDeletionJob).with(file_uri)
        end

        context 'the file is referenced in a course description' do
          let(:course) { create(:course, description: "The focus of this lecture is on this file: #{file_uri}") }

          it 'does not schedule the file deletion' do
            course
            expect { store }.not_to have_enqueued_job(S3FileDeletionJob).with(file_uri)
          end
        end
      end
    end
  end
end
