# frozen_string_literal: true

Rails.root.glob('db/seeds/development/*.rb').each {|f| require f }
