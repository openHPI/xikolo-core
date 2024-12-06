# frozen_string_literal: true

namespace :xikolo do
  require 'csv'

  desc <<~DESC
    Creates CSVs that hold information about regrading eligibility \
    of peer assessment participants.
  DESC

  task :regrading_evaluation, %i[csv_file threshold] => :environment do |_, args|
    csv_file = args[:csv_file]
    threshold = args[:threshold].to_f || 0.25
    participant_count = 0
    regrading_count = 0

    data = CSV.read(csv_file)
    CSV.open('tmp/peer_assessment_regrading_evaluation.csv', 'wb') do |csv|
      data.each_with_index do |row, i|
        if i == 0
          csv << [row[0..13], 'regrading possible?'].flatten
        else
          grade = row[3].to_i
          base_points = row[4].to_i
          regrading_request = row[5] == 'yes'
          puts regrading_request
          absolute_delta = row[6] == '-'
          received_reviews = (7..12).map {|j| row[j].to_i }

          max_points = 30
          regrading_possible =
            !regrading_request &&
            (received_reviews.count > 0) &&
            !grade.nil? &&
            !absolute_delta &&
            !base_points.nil? &&
            review_distance_exceeded?(received_reviews, max_points, threshold)
          regrading_count += 1 if regrading_possible
          participant_count += 1
          csv << [row[0..13], regrading_possible ? 'yes' : 'no'].flatten
        end
      end
    end

    $stdout.print "...finished.\n"
    $stdout.print format(
      "#{participant_count} participants, #{regrading_count} eligible for regrading (%.2f%%)\n",
      ((regrading_count.to_f / participant_count) * 100)
    )
    $stdout.flush
  end

  def review_distance_exceeded?(received_reviews, assessment_max_points, threshold)
    sorted_grades = received_reviews.sort

    if sorted_grades.count < 2
      return true
    end

    max_distance = (threshold * assessment_max_points).floor
    if (sorted_grades.first - sorted_grades.last).abs > max_distance
      if sorted_grades.count < 3 # there are no middle values
        return true
      end

      middle_grades = Array.new(sorted_grades)
      middle_grades.shift
      middle_grades.pop
      sum = 0
      middle_grades.each do |g|
        sum += g
      end
      average = (sum / middle_grades.count).floor
      if ((average - sorted_grades.first).abs > max_distance) && ((average - sorted_grades.last).abs > max_distance)
        return true
      end
    end

    false
  end
end
