# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localizations: Create', type: :request do
  subject(:action) { api.rel(:document).get(id: document.id).value!.rel(:localizations).post(create_params).value! }

  let!(:document) { create(:document, :english) }
  let(:create_params) { attributes_for(:document_localization) }
  let(:api) { Restify.new(:test).get.value }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_url) do
    "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/doc.pdf"
  end

  it { is_expected.to respond_with :created }

  it 'creates a new document localization' do
    expect { action }.to change(DocumentLocalization, :count).from(1).to(2)
  end

  context 'without description' do
    let(:create_params) { {title: 'title', document_id: document.id, language: 'de'} }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::UnprocessableEntity)
    end
  end

  context 'without title' do
    let(:create_params) { {description: 'descriptive description', document_id: document.id, language: 'de'} }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::UnprocessableEntity)
    end
  end

  context 'without language' do
    let(:create_params) { {title: 'title', description: 'descriptive description', document_id: document.id} }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::UnprocessableEntity)
    end
  end

  context 'with valid upload' do
    let(:create_params) { super().merge file_upload_id: upload_id }
    let!(:store_stub) do
      stub_request(:put, %r{https://s3.xikolo.de/xikolo-public/
        documents/[0-9a-zA-Z]+/de_v1.pdf}x).to_return(status: 200, body: '<xml></xml>')
    end

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{upload_id}/doc.pdf</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML

      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_document',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
    end

    it { is_expected.to respond_with :created }

    it 'stores the document in S3' do
      action
      expect(store_stub).to have_been_requested
    end
  end

  context 'with invalid file upload' do
    let(:create_params) { super().merge file_upload_id: upload_id }

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{upload_id}/doc.pdf</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
    end

    it 'returns an error on inprocessible upload' do
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_document',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'file_upload_id' => ['invalid upload']
      end
    end

    it 'handles S3 errors during upload validating' do
      stub_request(:head, file_url).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'file_upload_id' => ['could not process file upload']
      end
    end

    it 'handles S3 errors during upload copying' do
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_document',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )

      stub_request(:put, %r{https://s3.xikolo.de/xikolo-public/
        documents/[0-9a-zA-Z]+/de_v1.pdf}x).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'file_upload_id' => ['could not process file upload']
      end
    end
  end
end
