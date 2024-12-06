# frozen_string_literal: true

Sidekiq.default_job_options = {'max_retries' => 2}
