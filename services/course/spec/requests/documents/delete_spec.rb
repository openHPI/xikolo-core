# frozen_string_literal: true

require 'spec_helper'

describe 'Documents: Delete', type: :request do
  subject(:action) { api.rel(:document).delete({id: document.id}).value! }

  let!(:document) { create(:'course_service/document', :with_localizations) }

  let(:api) { Restify.new(:test).get.value }

  it 'responds with :no_content' do
    expect(action).to respond_with :no_content
  end

  it 'soft-deletes the document' do
    expect { action }.to change { document.reload.deleted }.from(false).to(true)
  end

  it 'recursively soft deletes all corresponding localizations' do
    expect { action }.to change { document.localizations.reload.all?(&:deleted) }.from(false).to(true)
  end
end
