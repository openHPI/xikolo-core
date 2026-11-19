# frozen_string_literal: true

namespace :pinboard_service do
  desc 'Backfill public answers, comments and answer comments counters on questions'
  task backfill_public_counters: :environment do
    PinboardService::Question.find_each do |question|
      question.update_public_answers_count!
      question.update_public_comments_count!
      question.update_public_answer_comments_count!
    end

    puts 'Backfill of public counters complete!'
  end
end
