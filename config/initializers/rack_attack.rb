# frozen_string_literal: true

ActiveSupport::Notifications.subscribe('login.failure') do |event|
  remote_ip = event.payload.fetch(:remote_ip)
  email = event.payload.fetch(:email)
  findtime = 5.minutes
  bantime = 1.hour
  maxretry = 15
  count = Rack::Attack.cache.count("login_scrapers_failure_count:#{remote_ip}_#{email}", findtime)

  Rack::Attack.cache.write("login_scrapers_blocked:#{remote_ip}_#{email}", 1, bantime) if count >= maxretry
end

class Rack::Attack
  # Throttle login per email (prevents brute force on one account)
  throttle('logins per email', limit: 10, period: 1.minute) do |req|
    if req.path == '/sessions' && req.post?
      req.params.dig('login', 'email')&.downcase&.strip
    end
  end

  throttle('logins per ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path == '/sessions' && req.post?
  end

  throttle('password reset per ip+email', limit: 5, period: 1.hour) do |req|
    if (req.path == '/account/reset') && req.post?
      email =
        req.params.dig(:reset, :email) ||
        req.params.dig('reset', 'email')

      "#{req.ip}-#{email&.downcase}" if email.present?
    end
  end

  blocklist('allow2ban login scrapers') do |req|
    next false unless req.post? && req.path == '/sessions'

    remote_ip = req.env['action_dispatch.remote_ip'].to_s
    email =
      begin
        req.params.dig('login', 'email')&.downcase
      rescue Rack::Multipart::EmptyContentError
        nil
      end

    cache.read("login_scrapers_blocked:#{remote_ip}_#{email}").present?
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

  self.throttled_responder = lambda do |request|
    req = Rack::Request.new(request.env)
    throttle_name = request.env['rack.attack.matched']
    match_data = request.env['rack.attack.match_data']

    Sentry.capture_message(
      'Rack::Attack throttle triggered',
      level: :warning
    ) do |scope|
      scope.set_tags(throttle: throttle_name)

      scope.set_context(
        'rack_attack',
        {
          ip: req.ip,
          email: req.params.dig('login', 'email') || req.params.dig('reset', 'email'),
          path: req.path,
          limit: match_data[:limit],
          period: match_data[:period],
        }
      )
    end

    msg = case req.path
            when '/sessions'
              'Too many login attempts. Please try again shortly.'
            when '/account/reset'
              'Too many password reset attempts. Please try again later.'
            else
              'Rate limit exceeded.'
          end

    [429, {'Content-Type' => 'text/plain'}, [msg]]
  end

  Rack::Attack.blocklisted_responder = lambda do |request|
    req = Rack::Request.new(request.env)
    ban_name = request.env['rack.attack.matched']
    match_data = request.env['rack.attack.match_data']

    Sentry.capture_message(
      'Rack::Attack blocklisted request blocked',
      level: :warning
    ) do |scope|
      scope.set_tags(throttle: ban_name)

      scope.set_context(
        'rack_attack',
        {
          ip: req.ip,
          email: req.params.dig('login', 'email') || req.params.dig('reset', 'email'),
          path: req.path,
          limit: match_data[:limit],
          period: match_data[:period],
        }
      )
    end

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
