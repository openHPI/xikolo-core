# frozen_string_literal: true

# Load seeds from multiple files, including environment-specific subdirectories.
#
# Seeds are first loaded from `db/seeds/all/**/*.rb`, followed by
# `db/seeds/<env>/**/*.rb`. The files will be ordered alphabetically each,
# before being required to ensure a consistent load order.
#
# The environment defaults to `Rails.env` but can be overridden by setting the
# SEED_ENV environment variable.

['all', ENV['SEED_ENV'] || Rails.env].each do |env|
  Rails.root.glob("db/seeds/#{env}/**/*.rb").each {|f| require f }
end
