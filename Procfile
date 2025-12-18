course: cd services/course && overmind start -p 3300
notification: cd services/notification && overmind start -p 3200

web: WORKERS=2 bin/rails server -p 3000
web-assets: yarn start
web-msgr: bundle exec msgr
web-sidekiq: bundle exec sidekiq
web-delayed: bin/rake delayed:work
