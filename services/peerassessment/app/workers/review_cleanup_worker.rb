# frozen_string_literal: true

class ReviewCleanupWorker
  include Sidekiq::Job

  def perform(review_id, ignore_pooling)
    begin
      review = Review.find review_id
    rescue ActiveRecord::RecordNotFound
      logger.error "Could not find review with id #{review_id}"
      return
    end

    # Check for an extension
    if review.deadline.future?
      review.schedule_worker clear: false # Do not clear the worker, it will terminate by itself.
      return
    end

    # Check submitted state but don't kill the review if suspended
    unless review.submitted || review.suspended?
      # Restore pool entry and destroy review
      if review.train_review
        # Increase train pool lock size
        pool = ResourcePool.find_by peer_assessment_id: review.peer_assessment.id, purpose: 'training'
      elsif !review.step.instance_of? Training
        # Treat train reviews done by students differently, since there is no locking count (== no pool)
        # (so only pick non-train-step non-train-review reviews)
        pool = ResourcePool.find_by peer_assessment_id: review.peer_assessment.id, purpose: 'review'
      else
        # Training step review. _NO_ pooling. Hence, only destroy the review
        review.delete
        return
      end

      begin
        PoolEntry.transaction do
          unless ignore_pooling
            entry = PoolEntry.lock.find_by submission_id: review.submission_id, resource_pool_id: pool.id
            entry.available_locks += 1
            entry.priority += 1 if pool.purpose == 'review' # Restore priority if in the peer grading pool
            entry.save!
          end

          review.delete
        end
      rescue
        # Transaction aborted, retry in 10 minutes
        logger.error "Transaction aborted for review with ID #{review.id}"
        review.schedule_worker explicit_deadline: 10.minutes.from_now
      end

      return
    end

    # A worker is no longer required, because the review is submitted and thus done
    # We disable the SkipsModelValidations cop here to avoid unintentional scheduling of new workers
    # rubocop:disable Rails/SkipsModelValidations
    review.update_column :worker_jid, nil
  end
end
# rubocop:enable all
