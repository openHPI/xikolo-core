# frozen_string_literal: true

require 'spec_helper'

describe Helpdesk::Ticket do
  subject { ticket }

  let(:course_id) { '00000001-3300-4444-9999-000000000001' }
  let(:ticket) do
    described_class.new(
      title: 'Problem',
      report: 'Something is not working',
      topic: 'course',
      course_id:,
      user_id: '00000001-aaaa-4444-9999-000000000001',
      mail: 'test@example.org',
      language: 'en'
    )
  end

  it { is_expected.to accept_values_for(:title, "I have a problem: It's not working!") }
  it { is_expected.not_to accept_values_for(:title, nil, '', 'Title with https://foo.example.com', "Long title: #{'x' * 300}") }
  it { is_expected.not_to accept_values_for(:report, nil, '') }
  it { is_expected.not_to accept_values_for(:topic, nil, '') }
  it { is_expected.not_to accept_values_for(:mail, nil, '', 'invalid.email') }
  it { is_expected.not_to accept_values_for(:language, nil, '') }

  context 'with course topic' do
    before { ticket.topic = 'course' }

    it { is_expected.to accept_values_for(:course_id, course_id) }
    it { is_expected.not_to accept_values_for(:course_id, nil, '') }
  end

  context 'with technical topic' do
    before { ticket.topic = 'technical' }

    it { is_expected.to accept_values_for(:course_id, nil, '') }
    it { is_expected.not_to accept_values_for(:course_id, course_id) }
  end

  it 'truncates overlong URLs' do
    overlong_url = "https://www.web.com/?AICC_SID=#{'x' * 300}"
    ticket.update(url: overlong_url)

    expect(overlong_url).to start_with ticket.url
    expect(ticket.url.size).to eq 255
  end

  context '(event publication)' do
    it 'publishes a RabbitMQ event' do
      expect(Msgr).to receive(:publish).with(
        kind_of(Hash),
        hash_including(to: 'xikolo.helpdesk.ticket.create')
      )
      ticket.save!
    end

    it '(asynchronously) sends an email to the helpdesk system' do
      expect { ticket.save! }.to have_enqueued_mail(Helpdesk::TicketMailer, :new_ticket_email)
    end
  end
end
