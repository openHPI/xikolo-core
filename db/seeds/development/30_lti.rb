# frozen_string_literal: true

# Development seeds for LTI tools / exercises.

Lti::Provider.create!(
  name: 'LTI Provider',
  description: 'Hands-on Programming',
  course_id: nil,
  domain: 'http://localhost:7000',
  consumer_key: 'consumer',
  shared_secret: 'secret',
  presentation_mode: 'window'
)

Lti::Provider.create!(
  name: 'TeamBuilder',
  course_id: nil,
  domain: 'http://localhost:4444',
  consumer_key: 'consumer',
  shared_secret: 'secret',
  presentation_mode: 'window'
)

Lti::Provider.create!(
  name: 'Saltire LTI provider (LTI testing tool)',
  course_id: nil,
  domain: 'https://lti.tools/saltire/tp',
  consumer_key: 'jisc.ac.uk',
  shared_secret: 'secret',
  presentation_mode: 'frame',
  privacy: 'anonymized'
)
