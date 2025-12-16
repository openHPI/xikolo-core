# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localizations for a Document: List', type: :request do
  subject(:list) do
    api.rel(:document).get({id: document1.id}).value!
      .rel(:localizations).get.value!
  end

  let!(:document1) { create(:'course_service/document') }
  let!(:document2) { create(:'course_service/document') }
  let!(:localization1) { create(:'course_service/document_localization') }
  let!(:localization2) { create(:'course_service/document_localization') }
  let!(:localization3) { create(:'course_service/document_localization') }

  let(:api) { Restify.new(course_service.root_url).get.value! }

  before do
    document1.localizations << localization1 << localization2
    document2.localizations << localization3
  end

  it { is_expected.to respond_with :ok }

  it 'shows only the localizations of document1' do
    expect(list.pluck('id')).to contain_exactly(localization1.id, localization2.id)
  end
end
