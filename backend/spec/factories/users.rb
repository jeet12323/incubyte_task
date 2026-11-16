FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "HR User #{n}" }
    sequence(:email) { |n| "hr#{n}@acme.test" }
    password { "correct-horse-battery" }
    role { "hr_manager" }

    trait :viewer do
      role { "viewer" }
    end
  end
end
