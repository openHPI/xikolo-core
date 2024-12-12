# frozen_string_literal: true

require 'spec_helper'

describe 'Documents: Create', type: :request do
  subject(:action) { api.rel(:documents).post(create_params).value! }

  let(:api) { Restify.new(:test).get.value }

  let(:create_params) { attributes_for(:document) }

  it 'responds with :created' do
    expect(action).to respond_with :created
  end

  it 'creates a new document' do
    expect { action }.to change(Document, :count).from(0).to(1)
  end

  context 'without description' do
    let(:create_params) { {title: 'title'} }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end
  end

  context 'without title' do
    let(:create_params) { {description: 'descriptive description'} }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end
  end

  context 'when title already exists' do
    before { create(:document, title: create_params[:title]) }

    it 'responds with 422 Unprocessable Entity' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end
  end

  context 'when title already exists, but in a deleted document' do
    before { create(:document, title: create_params[:title], deleted: true) }

    it 'responds with :created' do
      expect(action).to respond_with :created
    end

    it 'creates the new document' do
      expect { action }.to change(Document, :count).from(1).to(2)
    end
  end

  context 'with courses' do
    let!(:course1) { create(:course) }
    let(:create_params) { super().merge(course_ids: [course1.id]) }

    it 'creates the new document' do
      expect { action }.to change(Document, :count).from(0).to(1)
    end

    it 'connects document with said course' do
      action
      document = Document.first
      expect(document.course_ids).to eq([course1.id])
    end
  end
end
