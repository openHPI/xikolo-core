# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localization: Update', type: :request do
  subject(:action) { api.rel(:document_localization).patch(update_params, id: localization.id).value! }

  let!(:localization) do
    create(:document_localization,
      file_uri: 's3://xikolo-public/documents/1/de_v1.pdf')
  end
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_url) do
    "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/doc.pdf"
  end

  let(:api) { Restify.new(:test).get.value }

  let(:update_params) do
    {
      title: 'Updated title',
      description: 'Updated Description',
    }
  end

  it { is_expected.to respond_with :no_content }

  it 'changes the title' do
    expect { action }.to change { localization.reload.title }.to 'Updated title'
  end

  it 'changes the description' do
    expect { action }.to change { localization.reload.description }.to 'Updated Description'
  end

  context 'with valid upload' do
    let(:update_params) { super().merge file_upload_id: upload_id }
    let!(:store_stub) do
      stub_request(:put, %r{https://s3.xikolo.de/xikolo-public/
        documents/[0-9a-zA-Z]+/de_v2.pdf}x).to_return(status: 200, body: '<xml></xml>')
    end

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}") \
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

    it 'stores the document in S3' do
      action
      expect(store_stub).to have_been_requested
    end
  end

  context 'with invalid file upload' do
    let(:update_params) { super().merge file_upload_id: upload_id }

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}") \
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
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq 'file_upload_id' => ['invalid upload']
      end
    end

    it 'handles S3 errors during upload validating' do
      stub_request(:head, file_url).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
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
        documents/[0-9a-zA-Z]+/de_v2.pdf}x).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq \
          'file_upload_id' => ['could not process file upload']
      end
    end
  end
end
