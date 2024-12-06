# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    text { 'Lorem Ipsum' }
    submitted { false }
    award { false }
    train_review { false }
    deadline { 6.hours.from_now }
    optionIDs { [] }
    extended { false }
    user_id { SecureRandom.uuid }
    feedback_grade { nil }
    association :step, strategy: :create
    association :submission, strategy: :create

    trait :as_train_review do
      train_review { true }
    end

    trait :as_submitted do
      submitted { true }
    end

    trait :accused do
      after(:create) do |review|
        FactoryBot.create(:conflict,
          conflict_subject_type: 'Review',
          conflict_subject_id: review.id,
          reporter: review.submission.user_id)
      end
    end

    trait :suspended do
      # current_user_id { SecureRandom.uuid }
      after(:create) do |review|
        FactoryBot.create(:conflict,
          conflict_subject_type: 'Submission',
          conflict_subject_id: review.submission_id,
          reporter: review.user_id)
      end
    end

    before(:create) do |review|
      Stub.service(
        :account,
        user_url: '/users/{id}'
      )

      Stub.request(
        :account, :get, "/users/#{review.user_id}"
      ).to_return Stub.json({
        id: review.user_id,
        avatar_url: 'https://s3.xikolo.de/xikolo-public/avatar/003.jpg',
        email: 'test@example.de',
        permissions_url: "/permissions?user_id=#{review.user_id}",
      })

      Stub.request(
        :account, :get, "/permissions?user_id=#{review.user_id}"
      ).to_return Stub.json([])
    end
  end
end
