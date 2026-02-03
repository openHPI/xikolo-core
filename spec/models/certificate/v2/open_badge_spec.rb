# frozen_string_literal: true

require 'spec_helper'

describe Certificate::V2::OpenBadge, type: :model do
  # For version 2 Open Badges, we only test the correct type and assertion
  # All other model characteristics are inherited from Certificate::OpenBadge
  # and covered by the respective specs.

  subject(:badge) do
    described_class.create! open_badge_template: template, record:, **params
  end

  let(:params) { {} }
  let(:user) { create(:user, :with_email) }
  let(:course) { create(:course, records_released: true) }
  let(:template) { create(:open_badge_template, :full, course:) }
  let(:record) { create(:roa, user:, course:) }
  let(:uid) { UUID4(record.user_id).to_s(format: :base62) }
  let(:rid) { UUID4(record.id).to_s(format: :base62) }

  before do
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
    ).to_return(
      Stub.json(
        build_list(
          :'course:enrollment', 1, :with_learning_evaluation,
          course_id: course.id,
          user_id: user.id,
          completed_at: '2001-02-03'
        )
      )
    )
  end

  it 'sets the correct badge version for type' do
    expect(badge.type).to eql 'V2::OpenBadge'
  end

  describe '#bake!' do
    subject(:bake_badge) { badge.bake! }

    let(:assertion) do
      {
        '@context': 'https://w3id.org/openbadges/v2',
        type: 'Assertion',
        id: "https://xikolo.de/courses/#{course.course_code}/openbadges/v2/assertion/#{badge.id}",
        recipient: {
          type: 'email',
          hashed: true,
          identity: "sha256$#{Digest::SHA256.hexdigest user.email}",
        },
        badge: "https://xikolo.de/courses/#{course.course_code}/openbadges/v2/class.json",
        issuedOn: '2001-02-03T00:00:00Z',
        verification: {
          type: 'signed',
          creator: 'https://xikolo.de/openbadges/v2/public_key.json',
        },
        evidence: "https://xikolo.de/verify/#{record.verification}",
      }
    end

    before do
      xi_config file_fixture('badge_config.yml').read
      stub_request(:get, 'https://s3.xikolo.de/xikolo-certificate/openbadge_templates/1YLgUE6KPhaxfpGSZ.png')
        .with(query: hash_including({}))
        .to_return(
          body: Rails.root.join('spec/support/files/certificate/badge_template.png').open,
          status: 200,
          headers: {'Content-Type' => 'image/png'}
        )
      stub_request(:put, "https://s3.xikolo.de/xikolo-certificate/openbadges/#{uid}/#{rid}.png")
    end

    it 'persists the assertion' do
      expect { bake_badge }.to change(badge, :assertion).from(nil).to(assertion.as_json)
    end
  end
end
