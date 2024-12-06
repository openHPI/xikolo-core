# frozen_string_literal: true

module Xikolo::Common::Logging
  class LogFormatter
    def call(severity, datetime, _progname, msg)
      ::Kernel.format(
        "%s %5i %4s -- %s\n",
        datetime.utc.iso8601(1),
        Process.pid,
        severity,
        msg
      )
    end
  end
end
