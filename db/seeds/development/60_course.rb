# frozen_string_literal: true

# Course seed require the account service during
# seed creation.

begin
  `bundle exec rails server -p 3000 -d`

  6.times do |i|
    sleep 1
    Rails.logger.debug { "Waiting for Rails server to start #{i}/5" }
  end

  Rails.root.glob('db/seeds/development/60_course/*.rb').each {|f| require f }
ensure
  `kill -TERM $(cat tmp/pids/server.pid)`
end
