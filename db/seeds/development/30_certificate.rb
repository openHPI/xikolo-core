# frozen_string_literal: true

def upload_file(file, key, content_type)
  Xikolo::S3.bucket_for(:certificate)
    .put_object({
      key:,
      body: file,
      acl: 'private',
      content_type:,
    })
end

# Development seeds for certificate templates.
# ATTENTION: Validations are disabled as we cannot ensure that the xi-course
# seeds have been performed before.

roa_template_id = '00000001-3000-4444-9999-6e7f0a6d5f08'
ob_template_id = '00000001-3000-4444-9999-6e7f0a6d5f09'

roa = upload_file(File.open(File.join(Dir.pwd, 'spec', 'support', 'files', 'certificate', 'template.pdf')), 'templates/example.pdf', 'application/pdf')
badge = upload_file(File.open(File.join(Dir.pwd, 'spec', 'support', 'files', 'certificate', 'badge_template.png')), 'openbadges/example.png', 'image/png')
roa_uri = roa.storage_uri
ob_uri = badge.storage_uri

Certificate::Template.new(
  id: roa_template_id,
  dynamic_content: '<?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
      x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
      <g id="Dynamic_data">
      <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04"  font-size="21.6" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##NAME##</text>
      <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="174.26"  font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##EMAIL##</text>
      <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="215.138"  font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##BIRTHDAY##</text>
      <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="432.37"  font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##GRADE##</text>
      <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="453.37"  font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##TOP##</text>
      <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="470"  font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##VERIFY##</text>
      </g>
    </svg>',
  certificate_type: Certificate::Record::ROA,
  course_id: '00000001-3300-4444-9999-000000000001',
  file_uri: roa_uri
).save(validate: false)

Certificate::RecordOfAchievement.new(
  id: '00000001-3000-4444-9999-000000000099',
  user_id: '00000001-3100-4444-9999-000000000003',
  course_id: '00000001-3300-4444-9999-000000000001',
  template_id: roa_template_id,
  render_state: 'rendered'
).save(validate: false)

Certificate::OpenBadgeTemplate.new(
  id: ob_template_id,
  course_id: '00000001-3300-4444-9999-000000000001',
  file_uri: ob_uri
).save(validate: false)

Certificate::V2::OpenBadge.new(
  id: '00000002-3300-4444-9999-000000000001',
  record_id: '00000001-3000-4444-9999-000000000099',
  template_id: ob_template_id
).save(validate: false)

60.times do |i|
  Certificate::RecordOfAchievement.new(
    id: format('00000001-3000-4444-9999-0000000%05d', i + 100),
    user_id: format('00000001-3100-4444-9999-0000000%05d', i + 100),
    course_id: '00000001-3300-4444-9999-000000000001',
    template_id: roa_template_id,
    render_state: 'rendered'
  ).save(validate: false)
end
