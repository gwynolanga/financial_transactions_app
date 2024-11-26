# spec/factories/currencies.rb
FactoryBot.define do
  factory :currency do
    sequence(:name) { |n| "Currency#{n}" }
  end
end
