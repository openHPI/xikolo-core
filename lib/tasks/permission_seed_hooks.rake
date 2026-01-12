# frozen_string_literal: true

Rake::Task['db:seed'].enhance(['permissions:load'])
