# frozen_string_literal: true

def test_s3_host
  ENV.fetch('S3_PROVIDER_ENDPOINT')
end
