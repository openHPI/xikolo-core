# frozen_string_literal: true

class PeerAssessment < ApplicationRecord
  default_scope -> { order('created_at ASC') }

  has_many :steps, -> { order('position ASC') }
  has_many :shared_submissions, -> { order('created_at ASC') }
  has_many :submissions, -> { order('created_at ASC') }, through: :shared_submissions
  has_many :participants
  has_many :reviews, through: :submissions
  has_many :resource_pools
  has_many :rubrics, -> { order('position ASC') }
  has_many :conflicts, -> { order('created_at ASC') }
  has_many :files, class_name: 'PeerAssessmentFile'

  def submission_step
    steps.detect {|step| step.is_a? AssignmentSubmission }
  end

  def training_step
    steps.detect {|step| step.is_a? Training }
  end

  def grading_step
    steps.detect {|step| step.is_a? PeerGrading }
  end

  def self_assessment_step
    steps.detect {|step| step.is_a? SelfAssessment }
  end

  def results_step
    steps.detect {|step| step.is_a? Results }
  end

  def training_pool
    resource_pools.find_by(purpose: 'training')
  end

  def grading_pool
    resource_pools.find_by(purpose: 'review')
  end

  def passed?
    if steps.try(:last)
      steps.last.deadline.past?
    end
  end

  def max_points
    rubrics
      .joins(:rubric_options)
      .joins('LEFT JOIN rubric_options AS ro2 ' \
             'ON (rubric_options.rubric_id = ro2.rubric_id ' \
             'AND rubric_options.points < ro2.points)')
      .where(ro2: {points: nil})
      .sum('rubric_options.points')
  end
end
