# frozen_string_literal: true

require 'fileutils'

module CapybaraDownloads
  def download_directory
    @dir ||= CapybaraDownloads.download_directory.tap(&:mkpath) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def download_timeout
    30
  end

  def download_files
    Dir[download_directory.join('*')]
  end

  def clear_downloads!
    FileUtils.rm_f download_files
  end

  def expect_download
    wait_until_downloaded
  rescue Timeout::Error
    raise 'No download found'
  end

  def wait_until_downloaded
    Timeout.timeout(download_timeout) do
      sleep 0.1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && download_files.any?
  end

  def downloading?
    download_files.grep(/\.part$/).any?
  end

  class << self
    def download_directory
      Pathname.pwd.join('tmp', 'downloads')
    end
  end
end

Gurke.configure do |c|
  c.include CapybaraDownloads

  c.before(:scenario) do
    clear_downloads!
  end
end
