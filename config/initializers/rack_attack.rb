# frozen_string_literal: true

ActiveSupport::Notifications.subscribe('login.failure') do |event|
  remote_ip = event.payload.fetch(:remote_ip)
  findtime = 1.minute
  bantime = 1.hour
  maxretry = 15
  count = Rack::Attack.cache.count("login_scrapers_failior_count:#{remote_ip}", findtime)

  Rack::Attack.cache.write("login_scrapers_blocked:#{remote_ip}", 1, bantime) if count >= maxretry
end

class Rack::Attack
  blocklist('allow2ban login scrapers') do |req|
    remote_ip = req.env['action_dispatch.remote_ip'].to_s

    req.path == '/sessions' &&
      cache.read("login_scrapers_blocked:#{remote_ip}").present?
  end

  blocklist('allow2ban password reset bombing') do |req|
    remote_ip = req.env['action_dispatch.remote_ip'].to_s

    # Fall back to 'nil' for requests not made on password reset
    # In that case, this blocklist won't be used anyway
    mail_hash = Digest::SHA1.hexdigest(req.params.dig('reset', 'email')&.downcase || 'nil')

    Allow2Ban.filter(
      "#{remote_ip}---#{mail_hash}",
      maxretry: 10,
      findtime: 1.day,
      bantime: 1.day
    ) do
      req.path == '/account/reset' and req.post?
    end
  end

  safelist('allow from localhost') do |req|
    ['127.0.0.1', '::1'].include?(req.ip)
  end

  Rack::Attack.blocklisted_responder = lambda do |request|
    msg = case request.env['REQUEST_URI']
            when '/sessions'
              'Blocked due to too many login attempts.'
            when '/account/reset'
              'Blocked due to too many password reset attempts.'
            else
              'Blocked.'
          end

    [503, {}, [msg]]
  end
end
