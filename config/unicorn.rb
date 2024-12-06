# frozen_string_literal: true

# Application Unicorn Configuration

worker_processes ENV.fetch('WORKER', 1).to_i

logger Logger.new($stdout)
preload_app true
check_client_connection false
timeout ENV.fetch('UNICORN_TIMEOUT', 70).to_i

before_fork do |server, _worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.pid}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |_server, _worker|
  ActiveRecord::Base.establish_connection
end
