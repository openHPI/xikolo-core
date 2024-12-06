# frozen_string_literal: true

require 'spec_helper'

describe Certificate::OpenBadge, type: :model do
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
    Stub.service(:course, build(:'course:root'))
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
    expect(badge.type).to eql 'OpenBadge'
  end

  describe '#file_url' do
    subject(:badge_file_url) { badge.file_url }

    context 'without file URI' do
      let(:params) { super().merge file_uri: nil }

      it { is_expected.to be_nil }
    end

    context 'with file URI' do
      let(:file_uri) { 's3://xikolo-certificate/openbadges/user/record.png' }
      let(:params) { super().merge file_uri: }

      it { is_expected.to eq 'https://s3.xikolo.de/xikolo-certificate/openbadges/user/record.png' }
    end
  end

  describe '#bake!' do
    subject(:bake_badge) { badge.bake! }

    let(:assertion) do
      {
        '@context': 'https://w3id.org/openbadges/v1',
        type: 'Assertion',
        uid: UUID4(badge.id).to_s(format: :base62),
        id: "https://xikolo.de/courses/#{course.course_code}/assertion/#{UUID4(badge.id).to_s(format: :base62)}.json",
        recipient: {
          type: 'email',
          hashed: 'true',
          identity: "sha256$#{Digest::SHA256.hexdigest user.email}",
        },
        badge: "https://xikolo.de/courses/#{course.course_code}/badge.json",
        issuedOn: '2001-02-03',
        verify: {
          type: 'signed',
          url: 'https://xikolo.de/openbadges/public_key.json',
        },
        evidence: "https://xikolo.de/verify/#{record.verification}",
      }
    end
    let!(:s3_upload_stub) do
      stub_request(:put,
        "https://s3.xikolo.de/xikolo-certificate/openbadges/#{uid}/#{rid}.png")
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
    end

    it 'persists the baked badge' do
      expect { bake_badge }.to change { badge.reload.file_uri }.from(nil).to(
        "s3://xikolo-certificate/openbadges/#{uid}/#{rid}.png"
      )
      expect(s3_upload_stub).to have_been_requested
    end

    it 'persists the assertion' do
      expect { bake_badge }.to change(badge, :assertion).from(nil).to(assertion.as_json)
    end

    context 'with existing baked badge' do
      let(:params) do
        super().merge(
          file_uri: 's3://xikolo-certificate/openbadges/user/record.png'
        )
      end

      it 'does nothing' do
        expect { bake_badge }.not_to change(badge, :file_uri)
      end
    end

    context 'when baking fails' do
      let(:bakery) { instance_double(OpenBadgeBakery, bake: false) }

      before do
        allow(OpenBadgeBakery).to receive(:new).and_return bakery
      end

      it 'raises an error' do
        expect { bake_badge }.to raise_error Certificate::OpenBadge::BakingFailed
      end
    end

    context 'when storing the badge fails' do
      let(:s3_upload_stub) do
        stub_request(
          :put,
          "https://s3.xikolo.de/xikolo-certificate/openbadges/#{uid}/#{rid}.png"
        ).to_return(status: 403, body: '<xml></xml>')
      end

      before { s3_upload_stub }

      it 'raises an error' do
        expect { bake_badge }.to raise_error Certificate::OpenBadge::BakingFailed
      end
    end
  end

  context '(statistics)' do
    before do
      Stub.request(
        :course, :get, '/enrollments',
        query: hash_including(deleted: 'true', learning_evaluation: 'true')
      ).to_return(
        Stub.json(
          build_list(
            :'course:enrollment', 1, :with_learning_evaluation,
            completed_at: '2001-02-03'
          )
        )
      )

      create_list(:open_badge, 10, open_badge_template: template)
      create_list(:open_badge, 5)
    end

    describe '.issue_count' do
      it 'counts all Open Badges without given course' do
        expect(described_class.issue_count).to eq(15)
      end

      it 'counts Open Badges for given course' do
        expect(described_class.issue_count(course.id)).to eq(10)
      end
    end
  end
end
