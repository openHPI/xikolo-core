# frozen_string_literal: true

require 'spec_helper'

describe 'Document Localizations: Delete', type: :request do
  subject(:deletion) { api.rel(:document_localization).delete({id: localization_id}).value! }

  let!(:document) { create(:'course_service/document', :english) }
  let(:localization) { document.localizations.first }
  let(:localization_id) { localization.id }

  let(:api) { Restify.new(:test).get.value }

  it { is_expected.to respond_with :no_content }

  it 'soft-deletes the localization' do
    expect { deletion }.to change { localization.reload.deleted }.from(false).to(true)
  end

  it 'is not part of the corresponding document anymore' do
    expect { deletion }.to change { document.reload.localizations.size }.from(1).to(0)
  end
end
