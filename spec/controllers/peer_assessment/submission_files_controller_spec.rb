# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessment::SubmissionFilesController, type: :controller do
  describe '#gallery' do
    subject(:gallery) { get :gallery, params: }

    let(:params) { {peer_assessment_id: assessment_id, submission_id:, id: file_id} }
    let(:assessment_id) { SecureRandom.uuid }
    let(:submission_id) { SecureRandom.uuid }
    let(:file_id) { SecureRandom.uuid }
    let(:download_url) { 'https://s3.xikolo.de/pas/34/s/34/a/12.pdf' }

    before do
      Stub.service(:peerassessment, build(:'peerassessment:root'))
    end

    it 'redirects to the file download url' do
      Stub.request(:peerassessment, :get, "/peer_assessments/#{assessment_id}")
        .to_return Stub.json({gallery_entries: [submission_id]})
      Stub.request(:peerassessment, :get, "/shared_submissions/#{submission_id}")
        .to_return Stub.json({
          attachments: [
            {'id' => file_id, 'download_url' => download_url},
          ],
        })

      expect(gallery).to have_http_status :found
      expect(gallery).to redirect_to(download_url)
    end

    it 'returns a 404 for a unknown file' do
      Stub.request(:peerassessment, :get, "/peer_assessments/#{assessment_id}")
        .to_return Stub.json({gallery_entries: [submission_id]})
      Stub.request(:peerassessment, :get, "/shared_submissions/#{submission_id}")
        .to_return Stub.json({
          attachments: [
            {'id' => SecureRandom.uuid, 'download_url' => download_url},
          ],
        })

      expect { gallery }.to raise_error(Status::NotFound)
    end

    it 'returns a 404 for a non-gallery submission' do
      Stub.request(:peerassessment, :get, "/peer_assessments/#{assessment_id}")
        .to_return Stub.json({gallery_entries: [SecureRandom.uuid]})
      Stub.request(:peerassessment, :get, "/shared_submissions/#{submission_id}")
        .to_return Stub.json({
          attachments: [
            {'id' => file_id, 'download_url' => download_url},
          ],
        })

      expect { gallery }.to raise_error(Status::NotFound)
    end

    it 'returns a 404 for a non-existing submission' do
      Stub.request(:peerassessment, :get, "/peer_assessments/#{assessment_id}")
        .to_return Stub.json({gallery_entries: [submission_id]})
      Stub.request(:peerassessment, :get, "/shared_submissions/#{submission_id}")
        .to_return(status: 404)

      expect { gallery }.to raise_error(Status::NotFound)
    end

    it 'returns a 404 for a non-existing peerassessment' do
      Stub.request(:peerassessment, :get, "/peer_assessments/#{assessment_id}")
        .to_return(status: 404)

      expect { gallery }.to raise_error(Status::NotFound)
    end
  end
end
