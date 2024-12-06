# frozen_string_literal: true

class ConsentCookie
  def initialize(cookie_jar)
    @cookie_jar = cookie_jar
  end

  def accept(consent)
    return unless known? consent

    add consent, true
  end

  def decline(consent)
    return unless known? consent

    add consent, false
  end

  def current
    current_consent = (configured_consents - consent_list.keys).first
    return unless current_consent

    {
      name: current_consent,
      texts: config[current_consent],
    }
  end

  def accepted?(name)
    !!consent_list[name]
  end

  private

  def add(consent, accepted)
    consent_list[consent] = accepted

    @cookie_jar[:cookie_consents] = {value: JSON.generate(to_a), expires: 1.year}
  end

  def consent_list
    @consent_list ||= parse_cookie(@cookie_jar[:cookie_consents].to_s)
  end

  def to_a
    consent_list.map {|name, accepted| "#{accepted ? '+' : '-'}#{name}" }
  end

  def parse_cookie(json_str)
    parsed = JSON.parse(json_str)
    parsed.is_a?(Array) ? parsed.filter_map {|str| parse_consent(str) }.to_h : {}
  rescue JSON::ParserError
    {}
  end

  def parse_consent(consent_str)
    case consent_str
      when /^\+(\w+)$/
        [Regexp.last_match(1), true]
      when /^-(\w+)$/
        [Regexp.last_match(1), false]
    end
  end

  def config
    Xikolo.config.cookie_consents
  end

  def configured_consents
    config.keys
  end

  def known?(consent_name)
    configured_consents.include? consent_name
  end
end
