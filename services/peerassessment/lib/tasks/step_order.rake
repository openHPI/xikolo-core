# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Fixing step order in the prototype test
  DESC

  task step_order: :environment do
    AssignmentSubmission.all do |as|
      as.position = 1
      as.save! validate: false
    end

    Training.all do |t|
      t.position = 2
      t.save! validate: false
    end

    PeerGrading.all do |pg|
      pg.position = 3
      pg.save! validate: false
    end

    SelfAssessment.all do |sa|
      sa.position = 4
      sa.save! validate: false
    end

    Results.all do |rd|
      rd.position = 5
      rd.save! validate: false
    end

    $stdout.print '..ordering finished.'
    $stdout.flush
  end
end
