# frozen_string_literal: true

require 'spec_helper'

describe Review, type: :model do
  subject { review }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:step)        { assessment.steps[2] }

  let(:review_id)   { SecureRandom.uuid }
  let(:reviewer_id) { SecureRandom.uuid }

  let(:shared_submission) { create(:shared_submission, peer_assessment_id: assessment.id) }

  let(:submission) do
    create(:submission, :with_pool_entries,
      user_id: SecureRandom.uuid,
      shared_submission:)
  end

  let!(:review) do
    create(:review, id: review_id,
      step_id: step.id, user_id: reviewer_id,
      submission_id: submission.id,
      optionIDs: get_valid_rubrics(assessment))
  end

  describe 'validity' do
    it 'is valid' do
      expect(review).to be_valid
    end

    it 'is not valid without a set deadline' do
      review.deadline = nil
      expect(review).not_to be_valid
    end

    it 'is not valid without a user' do
      review.user_id = nil
      expect(review).not_to be_valid
    end

    it 'has the correct deadline' do
      expect(review.deadline).to be_within(5.minutes).of(DateTime.now + Review.relative_deadline)
    end
  end

  describe '.schedule_worker' do
    let(:review) do
      create(:review, id: SecureRandom.uuid,
        step_id: step.id, user_id: reviewer_id,
        submission_id: submission.id,
        optionIDs: get_valid_rubrics(assessment))
    end

    it 'enqueues a sidekiq worker' do
      expect do
        review.schedule_worker # Callbacks are not fired appropriately
      end.to change { ReviewCleanupWorker.jobs.size }.by(1)
    end
  end

  context 'with a regular review' do
    it 'is not possible to destroy the review' do
      expect(review.destroy).to be(false)
      expect(Review.exists?(review.id)).to be(true)
    end
  end

  describe '.rubric_options' do
    it 'returns something' do
      expect(review.rubric_options).not_to be_empty
    end

    it 'returns exactly three options' do
      expect(review.rubric_options.count).to eq(3) # 3 rubrics == 3 selections
    end
  end

  describe '.compute_grade' do
    it 'returns nil if not submitted' do
      expect(review.compute_grade).to be_nil
    end

    it 'returns an integer grade if submitted' do
      review.submitted = true
      review.save!

      expect(review.reload.compute_grade).to be_a(Integer)
    end
  end

  describe '.extend_deadline' do
    context 'without a truncation' do
      it 'extends the deadline by 2 hours' do
        expect do
          review.extend_deadline
        end.to change { review.reload.deadline }.by 2.hours
      end

      it 'sets the object flag appropriately' do
        review.extend_deadline
        expect(review.reload.extended).to be true
      end
    end

    context 'with a truncation' do
      it 'extends the deadline to the step deadline' do
        review.step.deadline = 1.hour.from_now
        review.step.save
        review.step.reload

        review.extend_deadline
        expect(review.reload.deadline).to eq(review.step.deadline)
      end
    end

    context 'with an already extended review' do
      it 'does not extend the deadline' do
        review.extend_deadline

        expect do
          review.extend_deadline
        end.not_to change { review.reload.deadline }
      end
    end
  end

  describe '.check_submission_exists' do
    it 'invalidates the record if no submission exists' do
      review.submission_id = SecureRandom.uuid
      expect(review).not_to be_valid
    end
  end

  it 'has a truncated deadline if the step deadline is less than 6h in the future' do
    step.deadline = 3.hours.from_now
    step.save!
    review.step.reload

    review.set_deadline
    review.save!

    expect(review.reload.deadline).to be_within(5.minutes).of(3.hours.from_now)
  end

  describe '(after_save) #check_feedback_state' do
    subject(:save_review) do
      review.feedback_grade = 2
      review.save!
    end

    let(:submission) { create(:submission, :with_grade) }
    let(:review) do
      create(:review,
        user_id: submission.user_id,
        submission:,
        submitted: true)
    end

    let(:course_result_id) { SecureRandom.uuid }
    let(:result_update_stub) do
      Stub.request(
        :course, :patch, "/results/#{course_result_id}",
        body: {points: 3.0}
      ).to_return Stub.response(status: 200)
    end

    before do
      Stub.service(:course, result_url: '/results/{id}')
      Stub.request(:course, :get, "/results/#{submission.id}")
        .to_return Stub.json({id: course_result_id})
      result_update_stub

      allow_any_instance_of(Grade).to receive(:compute_grade).and_return(3.0) # rubocop:disable RSpec/AnyInstance
    end

    it 'enqueues a ReviewRatingWorker job' do
      expect { save_review }.to change { ReviewRatingWorker.jobs.size }.from(0).to(1)
    end

    it 'updates the xi-course result' do
      Sidekiq::Testing.inline! { save_review }
      expect(result_update_stub).to have_been_requested.once
    end

    context 'feedback_grade not set' do
      subject(:save_review) { review.save! }

      it 'does not enqueue a ReviewRatingWorker job' do
        expect { save_review }.not_to change { ReviewRatingWorker.jobs.size }
      end
    end
  end

  describe '#suspended?' do
    subject { review.suspended? }

    context 'when a conflict exists' do
      before do
        create(:conflict, conflict_subject_id: submission.id, conflict_subject_type: 'Submission', reporter: reviewer_id,
          peer_assessment_id: assessment.id)
      end

      it { is_expected.to be true }
    end
  end

  describe 'not_accused' do
    let(:review1) { create(:review, :accused) }
    let(:review2) { create(:review) }

    it 'does not account the accused review for the grade' do
      expect(Review.not_accused.count).to eq(1)
    end
  end

  describe 'accounted' do
    let(:review1) { create(:review, :accused) }
    let(:review2) { create(:review, :suspended) }
    let(:review3) { create(:review) }

    it 'does not account the accused review for the grade' do
      expect(Review.not_accused.count).to eq(1)
    end
  end

  describe '.shared_submission' do
    subject { review.shared_submission }

    it { is_expected.to eq shared_submission }
  end

  describe '.peer_assessment' do
    subject { review.peer_assessment }

    it { is_expected.to eq assessment }
  end
end
