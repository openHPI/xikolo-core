# frozen_string_literal: true

require 'spec_helper'

describe Course::Richtext::Store, type: :operation do
  subject(:store) { described_class.new(richtext, params).call }

  let(:course) { create(:course) }
  let(:upload_id) { 'ecfde9ec-d464-4574-b518-56cd8d3282a0' }
  let(:params) { {text:, course_id: course.id} }
  let(:uri_regex) { %r{#{test_s3_host}/xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/#{file_name}}x }

  let(:read_upload_stub) do
    stub_request(:head, "#{test_s3_host}/xikolo-uploads/uploads/#{upload_id}/#{file_name}")
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
    let(:richtext) { CourseService::Richtext.new }
    let(:file_name) { 'richtext_image.png' }

    context 'when creating a new richtext item' do
      context 'without reference for an uploaded file' do
        let(:text) { 'Markup description (without an image reference)' }

        it 'updates the resource' do
          expect { store }.to change(CourseService::Richtext, :count).from(0).to(1)
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
          expect { store }.to change(CourseService::Richtext, :count).from(0).to(1)
          expect(CourseService::Richtext.take.text.to_s).to match(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/richtext_image.png}x)
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

  describe '(reading material)' do
    let(:file_name) { 'reading_material.pdf' }
    let(:file_url) { "#{test_s3_host}/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
    let(:store_stub_url) { %r{#{test_s3_host}/xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/reading_material.pdf} }
    let(:stored_uri_regex) { %r{s3://xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/reading_material.pdf} }

    def list_bucket_xml
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>xikolo-uploads</Name>
          <Prefix>uploads/#{upload_id}</Prefix>
          <IsTruncated>false</IsTruncated>
          <Contents>
            <Key>uploads/#{upload_id}/#{file_name}</Key>
            <LastModified>2018-08-02T13:27:56.768Z</LastModified>
            <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
          </Contents>
        </ListBucketResult>
      XML
    end

    def stub_upload(state)
      stub_request(:get, "#{test_s3_host}/xikolo-uploads?list-type=2&prefix=uploads%2F#{upload_id}")
        .to_return(status: 200, headers: {'Content-Type' => 'application/xml'}, body: list_bucket_xml)
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'richtext_material',
          'X-Amz-Meta-Xikolo-State' => state,
        }
      )
    end

    context 'when uploading' do
      let(:richtext) { CourseService::Richtext.new }
      let(:params) { {text: 'Some text', course_id: course.id, reading_material_upload_id: upload_id} }

      context 'with an accepted upload' do
        before do
          stub_upload 'accepted'
          stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>')
        end

        it 'stores the file and assigns the uri' do
          expect { store }.to change(CourseService::Richtext, :count).by(1)
          expect(WebMock).to have_requested(:put, store_stub_url)
          expect(CourseService::Richtext.last.reading_material_uri).to match(stored_uri_regex)
        end
      end

      context 'with a rejected upload' do
        before { stub_upload 'rejected' }

        it 'adds an upload error and saves nothing' do
          expect { store }.not_to change(CourseService::Richtext, :count)
          expect(richtext.errors[:reading_material_uri]).to be_present
        end
      end
    end

    context 'when replacing' do
      let(:old_uri) { 's3://xikolo-public/courses/oldId/rtfiles/ab12/reading_material.pdf' }
      let(:richtext) { create(:richtext, reading_material_uri: old_uri) }
      let(:params) { {text: 'Some text', reading_material_upload_id: upload_id} }

      before do
        stub_upload 'accepted'
        stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>')
      end

      it 'replaces the uri and deletes the old file' do
        expect { store }.to change { richtext.reload.reading_material_uri }
          .from(old_uri)
          .to(a_string_matching(stored_uri_regex))
          .and have_enqueued_job(S3FileDeletionJob).with(old_uri)
      end

      context 'when the old file is referenced by another richtext' do
        before { create(:richtext, reading_material_uri: old_uri) }

        it 'keeps the old file' do
          expect { store }.not_to have_enqueued_job(S3FileDeletionJob).with(old_uri)
          expect(richtext.reading_material_uri).to match(stored_uri_regex)
        end
      end
    end

    context 'when removing' do
      let(:old_uri) { 's3://xikolo-public/courses/oldId/rtfiles/ab12/reading_material.pdf' }
      let(:richtext) { create(:richtext, reading_material_uri: old_uri) }
      let(:params) { {text: 'Some text', reading_material_url: nil} }

      it 'clears the uri and deletes the file' do
        expect { store }.to change { richtext.reload.reading_material_uri }.from(old_uri).to(nil)
          .and have_enqueued_job(S3FileDeletionJob).with(old_uri)
      end
    end
  end
end
