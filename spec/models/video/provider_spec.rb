# frozen_string_literal: true

require 'spec_helper'

describe Video::Provider, type: :model do
  # Remove the default provider for these tests
  before { described_class.destroy_all }

  describe '(validations)' do
    subject(:new_provider) { build(:video_provider) }

    it { is_expected.to accept_values_for(:name, 'test') }
    it { is_expected.not_to accept_values_for(:name, '') }

    it { is_expected.to accept_values_for(:provider_type, 'kaltura', 'vimeo') }
    it { is_expected.not_to accept_values_for(:provider_type, '', nil, 'youtube') }

    context 'with existing provider' do
      let(:name) { 'test' }

      before { create(:video_provider, :vimeo, name:) }

      it { is_expected.not_to accept_values_for(:name, name) }
    end

    context 'with an existing default provider' do
      subject(:new_provider) { build(:video_provider, :vimeo, default: true) }

      before do
        create(:video_provider, :vimeo, default: true)
      end

      it { is_expected.not_to accept_values_for(:default, true) }
    end
  end

  describe '#sync' do
    let(:provider) { create(:video_provider, :vimeo) }

    context 'when doing full syncs' do
      let(:full) { true }

      it 'executes only one sync by aquiring a none wait lock' do
        allow(provider.send(:adapter)).to receive(:sync)

        sql = nil
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, payload|
          if payload[:sql].include?('FOR UPDATE')
            sql = payload[:sql]
          end
        end

        provider.sync(full:)

        ActiveSupport::Notifications.unsubscribe(subscriber)

        # Confirm that we are setting a none waiting lock on providers to abort
        # concurrent synchronization.
        expect(sql).to match(/\ASELECT "providers.+ FOR UPDATE NOWAIT\z/)
      end

      it 'raises an error from the failing sync' do
        allow(provider.send(:adapter)).to receive(:sync).and_raise(ActiveRecord::LockWaitTimeout)

        expect { provider.sync(full:) }.to raise_error(/Another sync for provider <.+> is still running/)
      end
    end

    context 'when doing partial syncs' do
      let(:full) { false }

      it 'executes only one sync by aquiring a none wait lock' do
        allow(provider.send(:adapter)).to receive(:sync)

        sql = nil
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, payload|
          if payload[:sql].include?('FOR UPDATE')
            sql = payload[:sql]
          end
        end

        provider.sync(full:)

        ActiveSupport::Notifications.unsubscribe(subscriber)

        # Confirm that we are setting a none waiting lock on providers to abort
        # concurrent synchronization.
        expect(sql).to match(/\ASELECT "providers.+ FOR UPDATE NOWAIT\z/)
      end

      it 'swallows the error from the failing sync' do
        allow(provider.send(:adapter)).to receive(:sync).and_raise(ActiveRecord::LockWaitTimeout)

        expect { provider.sync(full:) }.not_to raise_error
      end
    end
  end

  describe '#destroy' do
    subject(:destroy) { provider.destroy! }

    let(:provider) { create(:video_provider, :vimeo) }

    context 'with an associated stream' do
      let!(:stream) { create(:stream, provider:) }

      context 'when the stream is not referenced by a video' do
        it 'destroys provider and streams associated' do
          expect { destroy }.to change(Video::Provider, :count).from(1).to(0)
            .and change(Video::Stream, :count).from(1).to(0)
        end
      end

      context 'when the stream is referenced by a video' do
        before do
          create(:video, pip_stream: stream)
        end

        it 'does not destroy provider and streams associated' do
          expect { destroy }.to raise_error { ActiveRecord::DeleteRestrictionError }
          expect(provider.reload).not_to be_destroyed
          expect(stream.reload).not_to be_destroyed
        end
      end
    end
  end
end
