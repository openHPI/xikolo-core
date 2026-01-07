# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: creating new ones', type: :request do
  subject(:action) { api.rel(:teachers).post(data).value! }

  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let(:data) do
    {
      id: generate(:user_id),
      name: 'This is a text',
      description: {
        de: 'Deutsch!',
        en: 'English!',
      }.stringify_keys,
    }
  end

  context 'with valid parameters' do
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {
          de: 'Deutsch!',
          en: 'English!',
        }.stringify_keys,
      }
    end

    it { is_expected.to respond_with :created }

    it 'creates a new teacher object' do
      expect { action }.to change(CourseService::Teacher, :count).from(0).to(1)
    end
  end

  context 'with empty description' do
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {
          de: '',
          en: '',
        }.stringify_keys,
      }
    end

    it 'creates no new teacher object' do
      expect { action }.to raise_error(Restify::ClientError)
      expect(CourseService::Teacher.count).to eq 0
    end

    it 'raises an unprocessable entity error' do
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to include 'description'
      end
    end
  end

  context 'no user_id given' do
    let(:teacher_id) { generate(:user_id) }
    let(:data) do
      {
        id: teacher_id,
        name: 'This is a text',
        description: {
          de: 'Deutsch!',
          en: 'English!',
        }.stringify_keys,
      }
    end

    before { action }

    it 'has its user_id set to its id' do
      expect(CourseService::Teacher.first.user_id).to eq teacher_id
    end
  end

  context 'user_id given' do
    let(:user_id) { generate(:user_id) }
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {
          de: 'Deutsch!',
          en: 'English!',
        }.stringify_keys,
        user_id:,
      }
    end

    before { action }

    it 'has its user_id set to the provided value' do
      expect(CourseService::Teacher.first.user_id).to eq user_id
    end
  end

  context 'user_id is nil' do
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {
          de: 'Deutsch!',
          en: 'English!',
        }.stringify_keys,
        user_id: nil,
      }
    end

    before { action }

    it 'has its user_id set to nil' do
      expect(CourseService::Teacher.first.user_id).to be_nil
    end
  end
end
