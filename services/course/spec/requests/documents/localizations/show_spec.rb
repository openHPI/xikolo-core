# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localizations: Show', type: :request do
  subject(:resource) { api.rel(:document_localization).get({id: localization_id}).value! }

  let!(:document) { create(:'course_service/document', :english) }
  let(:localization) { document.localizations.first }
  let(:localization_id) { localization.id }

  let(:api) { Restify.new(:test).get.value }

  it { is_expected.to respond_with :ok }

  it 'contains all required attributes' do
    expect(resource.keys).to match_array %w[
      id
      title
      description
      language
      revision
      document_id
      deleted
      file_url
      url
      document_url
    ]
  end

  context 'soft-deleted localization' do
    before { localization.soft_delete }

    it 'responds with 404 Not Found' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end
end
