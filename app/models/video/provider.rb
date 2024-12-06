# frozen_string_literal: true

module Video
  class Provider < ::ApplicationRecord
    VALID_PROVIDER_TYPES = {
      'kaltura' => ProviderTypes::Kaltura,
      'vimeo' => ProviderTypes::Vimeo,
    }.freeze

    ADAPTER = {
      'kaltura' => KalturaAdapter,
      'vimeo' => VimeoAdapter,
    }.freeze

    has_many :streams, class_name: '::Video::Stream', dependent: :destroy

    validates :provider_type, presence: true, inclusion: VALID_PROVIDER_TYPES.keys
    validates :name, presence: true, uniqueness: true
    validate :uniqueness_of_default, if: -> { Provider.method_defined? :default }

    def uniqueness_of_default
      # make sure that this is the only default provider
      return unless default &&
                    Provider.where(default: true).where.not(id:).exists?

      errors.add(:default, 'default Provider already exists')
    end

    delegate :downloads_expire?, to: :adapter
    delegate :get_download_links, to: :adapter
    delegate :safe_metadata, to: :adapter
    delegate :sync_single, to: :adapter
    delegate :remove_subtitles!, to: :adapter
    delegate :attach_subtitles!, to: :adapter

    def sync_status
      @sync_status ||= if run_at != synchronized_at
                         :running
                       elsif synchronized_at.to_time.to_i == 0
                         :never_run
                       else
                         :completed
                       end
    end

    def sync_status_date
      case sync_status
        when :running
          run_at
        when :completed
          synchronized_at
        when :never_run
          nil
      end
    end

    def sync_status_locale
      case sync_status
        when :running
          I18n.t(:'admin.video_providers.index.status.running_since', begin: I18n.l(sync_status_date, format: :short))
        when :completed
          I18n.t(:'admin.video_providers.index.status.completed', begin: I18n.l(sync_status_date, format: :short))
        when :never_run
          I18n.t(:'admin.video_providers.index.status.never')
      end
    end

    def currently_syncing?
      sync_status == :running
    end

    def recently_synced?
      # The synchronisation has been started less than 1 hour ago.
      # It is either still running or has been completed (`synchronized_at`).
      # See the xi-video `Provider#sync` method for details.
      run_at&.after?(1.hour.ago)
    end

    def type
      @type ||= VALID_PROVIDER_TYPES.fetch(provider_type)
    end

    def sync(full: false)
      with_lock('FOR UPDATE NOWAIT') do
        update! run_at: (start = Time.current)
        adapter.sync(since: synchronized_at, full:)

        # Update time with start time to avoid potential missing
        # changes while having processed pages.
        update! synchronized_at: start
      end

      true
    rescue ActiveRecord::LockWaitTimeout
      # For partial syncs, we silently abort when another sync is still running.
      return false unless full

      raise SyncAlreadyRunning.new "Another sync for provider <#{name}> is still running"
    end

    private

    def adapter
      @adapter ||= ADAPTER[provider_type].new self
    end

    class SyncAlreadyRunning < RuntimeError; end
    class AuthenticationFailed < RuntimeError; end
    class AccountInactive < RuntimeError; end
  end
end
