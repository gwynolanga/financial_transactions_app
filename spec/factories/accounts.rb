# frozen_string_literal: true

# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    association :user
    association :currency
    balance { 1000.0 }
    sequence(:number) { |n| '1234567890123456'.first(16 - n.to_s.length) + n.to_s }
  end
end
