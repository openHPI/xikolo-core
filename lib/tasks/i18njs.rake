# frozen_string_literal: true

# Generate locals for JavaScript before asset precompile
Rake::Task['assets:precompile'].enhance(['assets:i18n:export'])
