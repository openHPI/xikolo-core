# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Creation', type: :request do
  subject(:resource) { api.rel(:groups).post(data).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) { {name: 'testowner.group_x'} }

  it 'responds with a created resource' do
    expect(resource).to respond_with :created
  end

  it 'responds with a follow location to created resource' do
    expect(resource.follow).to eq account_service.group_url(AccountService::Group.last)
  end

  it 'creates database record' do
    expect { resource }.to change(AccountService::Group, :count).from(0).to(1)
  end

  it 'returns created group' do
    expect(resource).to eq json(AccountService::Group.last)
  end

  context 'without name' do
    let(:data) { super().except(:name) }

    it 'withs a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'name' => %w[required invalid]
      end
    end
  end

  context 'with empty name' do
    let(:data) { {**super(), name: ''} }

    it 'withs a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'name' => %w[required invalid]
      end
    end
  end

  context 'with invalid name' do
    let(:data) { {**super(), name: 'abc'} }

    it 'withs a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'name' => %w[invalid]
      end
    end
  end

  context 'with duplicate name' do
    let(:data) { {**super(), name: 'xikolo.group'} }

    before do
      create(:'account_service/group', name: 'xikolo.group', description: 'Existing group.')
    end

    it 'withs a validation error' do
      expect { resource }.to raise_error Restify::ClientError do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'name' => %w[invalid]
      end
    end
  end

  context 'with group name with hyphen' do
    let(:data) { {**super(), name: 'course.test-course.students'} }

    it 'creates database record' do
      expect { resource }.to change(AccountService::Group, :count).from(0).to(1)
    end

    it 'responds with a created resource' do
      expect(resource).to respond_with :created
    end
  end
end
