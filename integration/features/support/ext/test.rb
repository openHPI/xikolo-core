# frozen_string_literal: true

module Test
  def wait(max: Capybara.default_max_wait_time, expect: [RSpec::Expectations::ExpectationNotMetError])
    yield
  rescue *expect => e
    sleep 0.5
    max -= 0.5
    max > 0 ? retry : raise(e)
  end
  module_function :wait

  def retry(max: 2)
    run = 0

    begin
      yield
    rescue StandardError => e
      run += 1
      raise e unless run <= max

      $stdout.puts "Retry unreliable test... (#{run}/#{max})"
      retry
    end
  end
  module_function :retry
end
