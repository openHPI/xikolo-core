# frozen_string_literal: true

require 'spec_helper'

describe Banner, type: :model do
  subject(:banner) { described_class.new params }

  let(:params) do
    {
      file_uri: 's3://xikolo-public/banners/banner.jpg',
      alt_text: 'Banner alternative text',
    }
  end

  describe '(validations)' do
    it { is_expected.not_to accept_values_for(:file_uri, nil) }
    it { is_expected.not_to accept_values_for(:alt_text, nil) }

    # Rails does not validate the presence, but Postgres has a constraint and
    # defaults to the current time.
    it { is_expected.to accept_values_for(:publish_at, nil) }

    it { is_expected.to accept_values_for(:link_url, nil) }
    it { is_expected.to accept_values_for(:link_target, nil) }
    it { is_expected.to accept_values_for(:expire_at, nil, 1.day.from_now) }

    it 'with link URL requires the link target to be specified' do
      expect do
        banner.update!(link_url: 'https://www.example.com')
      end.to raise_error ActiveRecord::RecordInvalid, /Link target can't be blank/
    end

    it 'with link target requires the link URL to be specified' do
      expect do
        banner.update!(link_target: 'self')
      end.to raise_error ActiveRecord::RecordInvalid, /Link URL can't be blank/
    end

    context 'with both the link URL and the link target provided' do
      let(:params) { super().merge(link_url: 'https://www.example.com', link_target: 'blank') }

      it { is_expected.to accept_values_for(:link_target, 'self', 'blank') }
      it { is_expected.not_to accept_values_for(:link_target, 'invalid', 1) }
    end

    it 'the publication date cannot be removed' do
      banner.save!
      expect(banner.reload.publish_at).to be_within(1.minute).of(Time.zone.now)
      expect do
        banner.update!(publish_at: nil)
      end.to raise_error ActiveRecord::NotNullViolation, /null value in column "publish_at"/
    end
  end

  describe '.active' do
    let(:active_banner1) { Banner.create! params.merge(publish_at: 3.days.ago) }
    let(:active_banner2) { Banner.create! params.merge(publish_at: 4.days.ago) }

    before do
      # Expired banner
      Banner.create! params.merge(publish_at: 1.week.ago, expire_at: 1.day.ago)
      # Active banners
      active_banner1
      active_banner2
      # Upcoming banner
      Banner.create! params.merge(publish_at: 1.week.from_now)
    end

    it 'only lists active (published and not already expired) banners' do
      expect(Banner.active.pluck(:id)).to eq [active_banner1.id, active_banner2.id]
    end
  end

  describe '.current' do
    let(:active_banner1) { Banner.create! params.merge(publish_at: 3.days.ago) }
    let(:active_banner2) { Banner.create! params.merge(publish_at: 4.days.ago) }

    before do
      # Expired banner
      Banner.create! params.merge(publish_at: 1.week.ago, expire_at: 1.day.ago)
      # Active banners
      active_banner1
      active_banner2
      # Upcoming banner
      Banner.create! params.merge(publish_at: 1.week.from_now)
    end

    it 'returns the current banner (first published, not expired)' do
      expect(Banner.current.id).to eq active_banner2.id
    end
  end

  describe '(deletion)' do
    around {|example| perform_enqueued_jobs(&example) }

    it 'deletes the referenced S3 object' do
      delete_stub = stub_request(
        :delete,
        'https://s3.xikolo.de/xikolo-public/banners/banner.jpg'
      )

      banner.destroy
      expect(delete_stub).to have_been_requested
    end
  end
end
