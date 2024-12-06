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
    context 'with concurrent syncs', transaction: false do
      # These tests must not be wrapped in a transaction, as each thread needs
      # its own transaction in order to acquire a lock.

      subject(:sync_in_thread) do
        lambda do |provider|
          allow(provider.send(:adapter)).to receive(:sync) do
            # We are letting each thread sleep a bit to ensure the locks conflict.
            sleep 1

            # Here (and in the thread below), we set a thread-local variable
            # that can be asserted against in the test scenarios below, to
            # check whether a provider did actually try to sync, or whether an
            # error was raised.
            Thread.current[:synced] = true
          end

          Thread.new do
            provider.sync(full:)
          rescue Video::Provider::SyncAlreadyRunning
            Thread.current[:aborted] = true
          end
        end
      end

      let(:provider) { create(:video_provider, :vimeo) }

      context 'with the same provider' do
        subject(:concurrent_syncs) do
          # We load the provider anew for each thread to avoid sharing internal state
          [
            sync_in_thread.call(Video::Provider.find(provider.id)),
            sync_in_thread.call(Video::Provider.find(provider.id)),
          ]
        end

        context 'when doing full syncs' do
          let(:full) { true }

          it 'executes only one sync' do
            # These assertions are written to check that e.g. one thread syncs,
            # but we don't care which one it is. This avoids order dependencies
            # on how the threads are scheduled.
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:synced] == true }, satisfy {|t| t[:synced].nil? })
          end

          it 'raises an error from the failing sync' do
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:aborted] == true }, satisfy {|t| t[:aborted].nil? })
          end
        end

        context 'when doing partial syncs' do
          let(:full) { false }

          it 'executes only one sync' do
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:synced] == true }, satisfy {|t| t[:synced].nil? })
          end

          it 'swallows the error from the failing sync' do
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:aborted].nil? }, satisfy {|t| t[:aborted].nil? })
          end
        end
      end

      context 'with two providers of the same type' do
        subject(:concurrent_syncs) do
          [
            sync_in_thread.call(Video::Provider.find(provider.id)),
            sync_in_thread.call(create(:video_provider, :vimeo)),
          ]
        end

        context 'when doing full syncs' do
          let(:full) { true }

          it 'fully executes both syncs' do
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:synced] == true }, satisfy {|t| t[:synced] == true })
          end
        end

        context 'when doing partial syncs' do
          let(:full) { false }

          it 'fully executes both syncs' do
            expect(concurrent_syncs.each(&:join)).to contain_exactly(satisfy {|t| t[:synced] == true }, satisfy {|t| t[:synced] == true })
          end
        end
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
