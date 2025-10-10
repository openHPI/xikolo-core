# frozen_string_literal: true

require 'spec_helper'

describe Event, type: :model do
  subject(:event) { create(:'notification_service/event') }

  describe 'validations' do
    it { is_expected.to accept_values_for :course_id, nil }
    it { is_expected.to accept_values_for :course_id, '7eeb2c46-104d-488c-a38b-fa17f5f42846' }

    it { is_expected.not_to accept_values_for :key, nil }
    it { is_expected.to accept_values_for :key, 'pinboard.new_answer' }

    it { is_expected.not_to accept_values_for :payload, nil }
    it { is_expected.to accept_values_for :payload, this: 'is a hash', another: 'pair' }
  end

  describe 'mail_payload' do
    subject(:payload) { event.mail_payload }

    it { is_expected.to be_a Hash }
    it { is_expected.to have_key 'link' }
    it { is_expected.to have_key 'timestamp' }
    it { is_expected.to have_key 'html' }

    describe '[html]' do
      subject(:html) { payload['html'] }

      before do
        event.payload = event.payload.merge(text: 'Text with *Markdown formatting*')
      end

      it { is_expected.to be_a String }

      it 'is the Markdown text converted to HTML' do
        expect(html).to eq "<p>Text with <em>Markdown formatting</em></p>\n"
      end
    end
  end
end
