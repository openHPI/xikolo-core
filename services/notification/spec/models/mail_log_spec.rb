# frozen_string_literal: true

require 'spec_helper'

describe MailLog, type: :model do
  subject(:mail_log) { described_class.new }

  describe 'validations' do
    it do
      expect(mail_log).to accept_values_for :state,
        'success', 'error', 'disabled', 'queued'
    end

    it do
      expect(mail_log).to accept_values_for :news_id,
        '00000001-3300-4444-9455-000000000001'
    end

    it { is_expected.to accept_values_for :course_id, nil }
    it { is_expected.not_to accept_values_for :user_id, nil }

    it do
      expect(mail_log).to accept_values_for :course_id,
        '00000001-3300-4444-9999-000000000001'
    end

    it { is_expected.to accept_values_for :key, nil }
    it { is_expected.to accept_values_for :key, 'course.notification' }
  end

  describe '#queue_if_unsent!' do
    subject(:queue!) do
      described_class.queue_if_unsent!(
        news_id:,
        user_id:,
        &block
      )
    end

    let(:block) { proc {} }
    let(:news_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }

    context 'when there is no matching MailLog entry' do
      it 'creates a new queued entry' do
        expect { queue! }.to change {
          described_class.where(
            news_id:, user_id:, state: 'queued'
          ).count
        }.from(0).to(1)
      end

      it 'executes the provided block' do
        expect do |block|
          described_class.queue_if_unsent!(
            news_id:, user_id:, &block
          )
        end.to yield_control
      end

      context 'when the provided block errors' do
        let(:block) { proc { raise 'RabbitMQ has gone away' } }

        it 'rolls back changes' do
          expect do
            queue!
          rescue RuntimeError
            # This is expected
          end.not_to change {
            described_class.where(
              news_id:, user_id:, state: 'queued'
            ).count
          }
        end
      end
    end

    context 'when there is a matching MailLog entry' do
      let!(:existing_log) do
        create(:'notification_service/mail_log',
          news_id:, user_id:, state:)
      end

      context 'in error state' do
        let(:state) { 'error' }

        it 'returns the existing entry in queued state' do
          expect(queue!).to have_attributes(
            id: existing_log.id,
            state: 'queued'
          )
        end

        it 'executes the provided block' do
          expect do |block|
            described_class.queue_if_unsent!(
              news_id:, user_id:, &block
            )
          end.to yield_control
        end

        context 'when the provided block errors' do
          let(:block) { proc { raise 'RabbitMQ has gone away' } }

          it "does not change the entry's state" do
            begin
              queue!
            rescue RuntimeError
              # This is expected
            end

            expect(existing_log.reload.state).to eq 'error'
          end
        end
      end

      context 'in success state' do
        let(:state) { 'success' }

        it 'returns the existing entry, unchanged' do
          expect(queue!).to have_attributes(
            id: existing_log.id,
            state: 'success'
          )
        end

        it 'does not execute the provided block' do
          expect do |block|
            described_class.queue_if_unsent!(
              news_id:, user_id:, &block
            )
          end.not_to yield_control
        end
      end

      context 'in disabled state' do
        let(:state) { 'disabled' }

        it 'returns the existing entry, unchanged' do
          expect(queue!).to have_attributes(
            id: existing_log.id, state: 'disabled'
          )
        end

        it 'does not execute the provided block' do
          expect do |block|
            described_class.queue_if_unsent!(
              news_id:, user_id:, &block
            )
          end.not_to yield_control
        end
      end

      context 'in queued state' do
        let(:state) { 'queued' }

        it 'returns the existing entry, unchanged' do
          expect(queue!).to have_attributes(
            id: existing_log.id, state: 'queued'
          )
        end

        it 'does not execute the provided block' do
          expect do |block|
            described_class.queue_if_unsent!(
              news_id:, user_id:, &block
            )
          end.not_to yield_control
        end
      end
    end
  end
end
