# frozen_string_literal: true

require 'spec_helper'

describe 'Cmi5 Contents: Show', type: :request do
  let(:cmi5_item) { create(:cmi5_item) }
  let(:blob_id) { cmi5_item.package.blob_id }

  before do
    Cmi5ItemUnzipJob.perform_now(cmi5_item)
  end

  it 'serves the entrypoint (story.html)' do
    get "/learn/#{cmi5_item.id}/content/#{blob_id}/story.html"

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq('text/html')
    expect(response.headers['Content-Disposition']).to start_with('inline')
    expect(response.body).to include('<!doctype html>')
  end

  it 'serves a text based asset' do
    get "/learn/#{cmi5_item.id}/content/#{blob_id}/html5/data/css/output.min.css"

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq('text/css')
    expect(response.headers['Content-Disposition']).to start_with('inline')
    expect(response.body).to include('@font-face')
  end

  it 'serves a binary asset' do
    get "/learn/#{cmi5_item.id}/content/#{blob_id}/story_content/thumbnail.jpg"

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq('image/jpeg')
    expect(response.headers['Content-Disposition']).to start_with('inline')
    expect(response.body).to include('JFIF')
  end

  it 'marks the response as publicly and immutably cacheable' do
    get "/learn/#{cmi5_item.id}/content/#{blob_id}/story.html"

    expect(response.headers['Cache-Control']).to include('public')
  end

  context 'with a blob id that does not match the current package' do
    it 'returns 404' do
      expect do
        get "/learn/#{cmi5_item.id}/content/#{SecureRandom.uuid}/story.html"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
