# frozen_string_literal: true

require 'webmock'

def set_xikolo_config(name, value)
  Server.each :config do |app|
    Rack::Remote.invoke app.id.to_sym, :set_xikolo_config, name:, value:
  end
end

def remote_stub(stub_name)
  Server.each :config do |app|
    Rack::Remote.invoke app.id.to_sym, stub_name
  end
end

Gurke.configure do |c|
  include WebMock::API

  c.before(:scenario) do |scenario|
    scenario.tags.each do |tag|
      case tag
        # with:flag
        # Enable boolean flags in Xikolo.config
        when /^with:(.+)$/
          set_xikolo_config(Regexp.last_match(1), true)

        # without:flag
        # Disable boolean flags in Xikolo.config
        when /^without:(.+)$/
          set_xikolo_config(Regexp.last_match(1), false)

        # feature:flipper_name
        # Assign a feature flipper to all platform users
        when /^feature:(.+)$/
          Server[:account].api
            .rel(:group).get({id: 'all'}).value!
            .rel(:features).patch({Regexp.last_match(1) => true}).value!

        when /recaptcha_v3/
          remote_stub(:stub_recaptcha_v3)
        when /recaptcha_v2/
          remote_stub(:stub_recaptcha_v2)
      end
    end
  end

  c.after(:scenario) do |scenario|
    scenario.tags.each do |tag|
      case tag
        when /^recaptcha_(.+)$/
          # Reset the stubs after each scenario with a recaptcha tag
          remote_stub(:reset_stubs)
      end
    end
  end
end
