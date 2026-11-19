# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::FileDeletionJob, type: :job do
  let(:encoded_course_id) { UUID4.new.to_s(format: :base62) }
  let(:uri) { "s3://xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg" }

  describe '#perform' do
    it 'removes the S3 object' do
      deletion = stub_request(
        :delete,
        "#{test_s3_host}/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 200)

      perform_enqueued_jobs do
        described_class.perform_later(uri)
      end

      expect(deletion).to have_been_requested
    end

    it 'raises an S3 error' do
      stub_request(
        :delete,
        "#{test_s3_host}/xikolo-public/courses/#{encoded_course_id}/encodedUUUID/visual.jpg"
      ).to_return(status: 500)

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(uri)
        end
      end.to raise_error do |error|
        # ActiveJob wraps the exception
        expect(error.cause).to be_a(Aws::S3::Errors::Http500Error)
      end
    end
  end
end
