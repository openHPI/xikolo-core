# frozen_string_literal: true

class SystemInfoController < ApplicationController
  def show
    deb_version = ENV['DEB_VERSION'] ||
                  "0.0+t#{Time.now.utc.strftime('%Y%m%d%H%M')}+b0-1"

    version, time, build_number = deb_version.split('-')[0].split('+')

    render json: {
      running: true,
      build_time: DateTime.strptime(time, 't%Y%m%d%H%M').iso8601,
      build_number: build_number[1..].to_i,
      version:,
      hostname: Socket.gethostname,
    }
  end
end
