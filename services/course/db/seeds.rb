# frozen_string_literal: true

# Why do we have this code?
#
# This is supposed to be a fix for the draper issue described here:
# https://github.com/drapergem/draper/issues/256#issuecomment-17654836 The
# referenced issue happens when a Draper::Decorator is executed as part of a
# rake execution (e.g. rake db:seed) and this Draper::Decorator uses a
# DraperHelper to resolve some object URLs. An for this situation can be found
# in the app/decorator/course_decorator.rb in line 25, see below.
#
#     class CourseDecorator < Draper::Decorator
#       ...
#       def as_api_v1(opts)
#         {
#           ...
#           url: h.url_for(model), # h is the draper_helper
#           ...
#         }
#       end
#     end
#
# Why is a Draper::Decorator called during a 'rake db:seed'? Domain models, such
# as Course and Item, publish a RabbitMQ events with a decorated version of the
# newly created object (created through the rake db:seed).
#
# When executing in a 'normal' Rails way, this is not an issue, because the
# Rails setup will take care of setting the route_helper properly that will be
# used by the draper_helper at some point. In contrast, when we execute a rake
# task then the necessary route_helper will be nil which leads to a respective
# Ruby NilPointerException.

# Rails.application.routes.default_url_options = {host: 'localhost:3300'}
# module Draper
#   class HelperProxy
#     include Rails.application.routes.url_helpers
#     default_url_options[:host] = ::Rails.application.routes.default_url_options[:host]
#   end
# end

# Meta seed file that required depending on the Rails env different files from
# db/seeds/ Please put the seed in the best matching file
#
#   * all: Objects are needed in every environment (production, development)
#     like Custom Fields ..
#   * production: Objects are only needed for deployment (e.g. Admin user with
#     strong password)
#   * development: Only needed for local experimenting (e.g. Admin user with
#     week user ...)
#
# Set the SEED_ENV environment variable to load a specific seed file

['all', ENV['SEED_ENV'] || Rails.env].each do |seed|
  seed_file = Rails.root.join("db/seeds/#{seed}.rb")
  if seed_file.exist?
    puts "*** Loading \"#{seed}\" seed data"
    load seed_file
  else
    puts "*** Skipping \"#{seed}\" seed data: \"#{seed_file}\" not found"
  end
end
