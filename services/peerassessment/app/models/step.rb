# frozen_string_literal: true

class Step < ApplicationRecord
  require 'sidekiq/api'

  belongs_to :peer_assessment

  validates :position, :type, presence: true
  validates_uniqueness_of :type, scope: :peer_assessment_id
  validates_uniqueness_of :position, scope: :peer_assessment_id

  before_update :reschedule_deadline_workers
  before_update :update_item_submission_publish_date, if: proc {|step|
    step.peer_assessment.steps[-2] == step && step.deadline_changed?
  }

  default_scope { order('position ASC') }

  # Checks general accessibility of the step (for students)
  def open?
    deadline.try(:future?) && (unlock_date.nil? || unlock_date.try(:past?))
  end

  # [0, 1] coded percentage
  def completion(_user_id)
    raise NotImplementedError
  end

  def complete?(user_id)
    completion(user_id).to_d == BigDecimal('1.0')
  end

  def skippable?(user_id)
    (completion(user_id).to_d == BigDecimal('0.0')) && optional
  end

  # Called when a user advances to a step. Default behavior is to do nothing, may be overwritten by subclasses.
  # Implementation is required to be idempotent.
  def on_step_enter(user_id); end

  def advance_team?
    peer_assessment.is_team_assessment && advance_team_to_step?
  end

  # If one team member advances to this this step
  # should other team members be advanced as well?
  # Change this behavior in subclasses.
  def advance_team_to_step?
    false
  end

  # Updates the peer assessment item(s) to reflect the new result publish deadline,
  # which is always the deadline of the second last step.
  def update_item_submission_publish_date
    course_api = Xikolo.api(:course).value!
    items = course_api.rel(:item).get(content_id: peer_assessment.id).value!
    items.map do |item|
      course_api.rel(:item).patch({submission_publishing_date: deadline}, {id: item['id']})
    end.map(&:value!)
  end

  def next_step
    Step.unscoped.where(
      peer_assessment_id:
    ).where('position > ?', position).order('position ASC').limit(1).take
  end

  def previous_step
    Step.unscoped.where(
      peer_assessment_id:
    ).where(position: ...position).order('position DESC').limit(1).take
  end

  def first?
    previous_step.nil?
  end

  ### Deadline Worker Methods ###

  # Schedules workers to run at the end of the deadline. No workers by default, may be overridden by subclasses.
  def schedule_deadline_workers; end

  # Reschedules the worker to run at the step deadline (triggered on update if the deadline changed)
  def reschedule_deadline_workers
    if deadline_changed?
      if deadline_worker_jids.empty?
        # Setup new workers through a hook each subclass can override
        schedule_deadline_workers
      else
        # Reschedule each worker according to the new deadline
        reschedule_workers
      end
    end
  end

  def reschedule_workers
    deadline_worker_jids.each do |worker_jid|
      reschedule_worker worker_jid
    end
  end

  def reschedule_worker(worker_jid)
    # Execute the worker in given time or ASAP (with small buffer)
    Sidekiq::ScheduledSet.new.find_job(worker_jid).try(:reschedule, schedule_time)
  end

  def schedule_time
    # Have some buffer when rescheduling.
    deadline.past? ? DateTime.now + 5.seconds : deadline
  end
end
