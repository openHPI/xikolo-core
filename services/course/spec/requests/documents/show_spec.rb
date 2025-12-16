# frozen_string_literal: true

require 'spec_helper'

describe 'Documents: Show', type: :request do
  subject(:action) { api.rel(:document).get(params).value! }

  let(:document) { create(:'course_service/document', :with_localizations) }

  let(:api) { Restify.new(course_service.root_url).get.value }

  let(:params) { {id: document.id} }

  it { is_expected.to respond_with :ok }

  it 'contains all required attributes' do
    expect(action.keys).to match_array %w[
      id
      title
      description
      tags
      public
      localizations
      url
      localizations_url
    ]
  end

  describe '(embedding course_ids)' do
    let(:params) { super().merge(embed: 'course_ids') }

    it { expect(action['course_ids']).to be_an Array }
    it { expect(action).not_to have_key 'items' }
  end

  describe '(embedding items)' do
    let(:params) { super().merge(embed: 'items') }

    it { expect(action['items']).to be_an Array }
    it { expect(action).not_to have_key 'courses' }
  end

  describe '(embedding course_ids and items)' do
    let(:params) { super().merge(embed: 'course_ids,items') }

    it { expect(action['course_ids']).to be_an Array }
    it { expect(action['items']).to be_an Array }
  end

  context 'with a non-existent ID' do
    let!(:localization) { create(:'course_service/document_localization') }
    let(:params) { {id: localization.id} }

    it 'responds with 404 Not Found' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  context 'deleted document' do
    let(:document) { create(:'course_service/document', deleted: true) }

    it 'responds with 404 Not Found' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end
end
