# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localizations: List', type: :request do
  subject(:list) { api.rel(:document_localizations).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }

  before { create_list(:'course_service/document_localization', 3) }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(3).items }

  it 'contains all required attributes' do
    expect(list.map(&:keys)).to all(match_array(%w[
      id
      title
      description
      deleted
      file_url
      revision
      language
      document_id
      url
      document_url
    ]))
  end
end
