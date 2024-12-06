# frozen_string_literal: true

class Rack::Attack
  blocklist('allow2ban login scrapers') do |req|
    Allow2Ban.filter(
      req.env['action_dispatch.remote_ip'].to_s,
      # we still need the values (required)
      maxretry: 1,
      findtime: 1.minute,
      bantime: 1.hour
    ) do
      # do not trigger the filter from here
      false
    end
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
    req.ip == '127.0.0.1' || req.ip == '::1'
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
