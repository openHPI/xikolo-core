# frozen_string_literal: true

FactoryBot.define do
  factory :step do
    association :peer_assessment, strategy: :create
    sequence :position
    optional { false }
    type { 'Step' }
    deadline { 1.day.from_now }

    trait :optional do
      optional { true }
    end

    trait :locked do
      unlock_date { 1.day.from_now }
    end

    trait :passed do
      deadline { 1.day.ago }
    end

    factory :assignment_submission, class: 'AssignmentSubmission' do
      type { 'AssignmentSubmission' }
      deadline { 3.days.from_now }
    end

    factory :training, class: 'Training' do
      type { 'Training' }
      deadline { 1.week.from_now }
      required_reviews { 3 }
      open { false }

      trait :open_training do
        open { true }
      end

      ## this is handled by the model
      # after(:create) do |step|
      #   if step.peer_assessment
      #     step.peer_assessment.resource_pools << FactoryBot.create(:resource_pool, purpose: 'training', peer_assessment: step.peer_assessment)
      #   end
      # end
    end

    factory :peer_grading, class: 'PeerGrading' do
      type { 'PeerGrading' }
      deadline { 1.week.from_now }
      required_reviews { 3 }

      ## this is handled by the model
      # after(:create) do |step|
      #   if step.peer_assessment
      #     step.peer_assessment.resource_pools << FactoryBot.create(:resource_pool, purpose: 'review', peer_assessment: step.peer_assessment)
      #   end
      # end
    end

    factory :self_assessment, class: 'SelfAssessment' do
      type { 'SelfAssessment' }
      deadline { 1.week.from_now }
    end

    factory :results, class: 'Results' do
      type { 'Results' }
      deadline { 2.weeks.from_now }
    end
  end
end
