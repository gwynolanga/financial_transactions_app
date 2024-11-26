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

    trait :completed do
      status { :completed }
    end

    trait :deferred do
      status { :deferred }
    end

    trait :canceled do
      status { :canceled }
    end
  end
end
