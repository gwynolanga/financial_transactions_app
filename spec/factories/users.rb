# frozen_string_literal: true

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    full_name { 'John Doe Example' }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
  end
end
