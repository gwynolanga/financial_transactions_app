# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    association :user
    association :currency
    balance { 1000.0 }
    sequence(:number) { |n| "12345678901234#{n.to_s.rjust(2, '0')}" }
  end
end
