# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::RichtextFileDeletionWorker, type: :worker do
  let(:encoded_course_id) { UUID4.new.to_s(format: :base62) }
  let(:uri) { "s3://xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg" }

  describe '#perform' do
    it 'removes the S3 object' do
      deletion = stub_request(
        :delete,
        "https://s3.xikolo.de/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 200)

      Sidekiq::Testing.inline! do
        described_class.perform_async(uri)
      end

      expect(deletion).to have_been_requested
    end

    it 'raises an S3 errors' do
      stub_request(
        :delete,
        "https://s3.xikolo.de/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 500)

      expect do
        Sidekiq::Testing.inline! do
          described_class.perform_async(uri)
        end
      end.to raise_error(Aws::S3::Errors::Http500Error)
    end

    it 'keeps object if referenced in a course description' do
      create(:'course_service/course', description: "Headline\n#{uri}")
      deletion = stub_request(
        :delete,
        "https://s3.xikolo.de/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 200)

      Sidekiq::Testing.inline! do
        described_class.perform_async(uri)
      end

      expect(deletion).not_to have_been_requested
    end

    it 'keeps object if referenced in a richtext text' do
      create(:'course_service/richtext', text: "Headline\n#{uri}")
      deletion = stub_request(
        :delete,
        "https://s3.xikolo.de/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 200)

      Sidekiq::Testing.inline! do
        described_class.perform_async(uri)
      end

      expect(deletion).not_to have_been_requested
    end
  end
end
