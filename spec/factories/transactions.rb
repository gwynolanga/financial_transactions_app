# frozen_string_literal: true

# spec/factories/transactions.rb
FactoryBot.define do
  factory :transaction do
    association :sender, factory: :account
    association :recipient, factory: :account
    sender_amount { 100.0 }
    recipient_amount { 100.0 }
    kind { :immediate }
    status { :pending }
    execution_date { nil }

    trait :completed do
      status { :completed }
    end

    trait :deferred do
      status { :deferred }
      execution_date { 1.day.from_now }
    end

    trait :canceled do
      status { :canceled }
    end

    trait :failed do
      status { :failed }
    end

    trait :scheduled do
      kind { :scheduled }
      execution_date { 1.day.from_now }
    end

    trait :deposit do
      kind { :deposit }
      sender { nil }
      recipient_amount { 0.0 }
    end

    trait :withdrawal do
      kind { :withdrawal }
      recipient { nil }
      sender_amount { 0.0 }
    end
  end
end
