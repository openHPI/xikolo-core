# frozen_string_literal: true

module MetricsHelper
  def wait_intervals
    [[I18n.t(:'admin.user_tests.new.none'), 0]] +
      [1.minute, 2.minutes, 3.minutes, 4.minutes, 5.minutes, 10.minutes,
       30.minutes, 1.hour, 2.hours, 6.hours, 12.hours, 1.day, 2.days,
       1.week, 2.weeks, 3.weeks, 4.weeks].map do |time|
        [wait_interval_to_string(time), time]
      end
  end

  def wait_interval_to_string(wait_interval)
    distance_of_time_in_words(wait_interval).sub('about ', '').sub('etwa ', '')
  end
end
