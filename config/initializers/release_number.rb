# frozen_string_literal: true

if File.exist? '/usr/share/xikolo/release_number'
  ENV['RELEASE_NUMBER'] = File.read('/usr/share/xikolo/release_number').strip
end
