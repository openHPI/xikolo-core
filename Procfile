account: cd services/account && overmind start -p 3100
course: cd services/course && overmind start -p 3300
news: cd services/news && overmind start -p 4300
notification: cd services/notification && overmind start -p 3200
pinboard: cd services/pinboard && overmind start -p 3500
quiz: cd services/quiz && overmind start -p 3800
timeeffort: cd services/timeeffort && overmind start -p 6300

web: bin/rails server -p 3000
web-assets: yarn start
web-msgr: bundle exec msgr
web-sidekiq: bundle exec sidekiq
web-delayed: bin/rake delayed:work
