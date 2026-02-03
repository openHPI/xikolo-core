# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PinboardService::Course, type: :model do
  before do
    course_stub
  end

  let(:course_stub) do
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({
        course_code: 'code2019',
        lang: 'fi',
      })
  end
  let(:course_id) { generate(:course_id) }

  describe '.find' do
    it 'returns a course record' do
      record = described_class.find(course_id)

      expect(record.code).to eq 'code2019'
      expect(record.language).to eq 'fi'
    end

    it 'caches the response' do
      with_caching do
        expect(Rails.cache.exist?("pinboard/v1/course/#{course_id}")).to be false
        2.times { described_class.find(course_id) }

        expect(course_stub).to have_been_requested.once
        expect(Rails.cache.exist?("pinboard/v1/course/#{course_id}")).to be true
      end
    end

    context 'when the course does not exist' do
      let(:course_stub) do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.response(status: 404)
      end

      it 'raises an exception' do
        expect do
          described_class.find(course_id)
        end.to raise_error(PinboardService::Course::NotFound)
      end
    end
  end
end
