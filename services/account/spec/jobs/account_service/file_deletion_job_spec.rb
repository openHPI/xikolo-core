# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::FileDeletionJob, type: :job do
  describe '#perform' do
    it do
      deletion = stub_request(
        :delete,
        'http://s3.xikolo.de/xikolo-public/avatars/34/avatar_v1.jpg'
      )

      perform_enqueued_jobs do
        described_class.perform_later(
          's3://xikolo-public/avatars/34/avatar_v1.jpg'
        )
      end

      expect(deletion).to have_been_requested
    end
  end
end
