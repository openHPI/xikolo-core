# frozen_string_literal: true

# Meta seed file that required depending on the Rails env different files from db/seeds/
# Please put the seed in the best matching file
#   all: Objects are needed in every environment (production, development) like Custom Fields ..
#   production: Objects are only needed for deployment (e.g. Admin user with strong password)
#   development: Only needed for local experimenting (e.g. Admin user with week user ...)
# Set the SEED_ENV environment variable to load a specific seed file

['all', ENV['SEED_ENV'] || Rails.env].each do |seed|
  seed_file = "#{Rails.root}/db/seeds/#{seed}.rb"
  if File.exist?(seed_file)
    puts "*** Loading \"#{seed}\" seed data"
    load seed_file
  else
    puts "*** Skiping \"#{seed}\" seed data: \"#{seed_file}\" not found"
  end
end
