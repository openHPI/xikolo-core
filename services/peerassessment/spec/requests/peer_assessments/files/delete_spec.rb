# frozen_string_literal: true

require 'spec_helper'

describe 'PeerAssessment Files: Delete', type: :request do
  subject(:deletion) do
    assessment_resource.rel(:file).delete(id: file.id).value!
  end

  let(:user_id) { SecureRandom.uuid }
  let(:test_api) { Restify.new(:test).get.value! }
  let(:assessment_resource) { test_api.rel(:peer_assessment).get(id: assessment.id).value! }
  let!(:assessment) { create(:peer_assessment) }
  let!(:file) { create(:peer_assessment_file, storage_uri: 's3://xikolo-pa/pas/34/a/23_img.jpg', peer_assessment: assessment) }

  it 'removes the file from database and s3' do
    s3_deletion = stub_request(:delete,
      'https://s3.xikolo.de/xikolo-pa/pas/34/a/23_img.jpg')
    expect { deletion }.to change(PeerAssessmentFile, :count).from(1).to(0)
    expect(s3_deletion).to have_been_requested
  end
end
