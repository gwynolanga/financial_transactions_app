# frozen_string_literal: true

unless User.exists?
  1.upto(3) do |i|
    User.create!(full_name: FFaker::Name.name.to_s, email: "user#{i}@example.com",
                 password: "password_#{i}", password_confirmation: "password_#{i}")
  end
end

%w[USD GBP EUR GEL].each { |currency| Currency.create!(name: currency) } unless Currency.exists?

unless ExchangeRate.exists?
  Currency.find_each.to_a.combination(2).each do |base_currency, target_currency|
    ExchangeRate.create!(value: rand(1.5..4.5), base_currency: base_currency, target_currency: target_currency)
  end
end

unless Account.exists?
  User.find_each do |user|
    Currency.find_each do |currency|
      number = SecureRandom.random_number(10**16).to_s.rjust(16, '0')
      Account.create!(user: user, currency: currency, number: number, balance: rand(1000..5_000))
    end
  end
end

unless Transaction.exists?
  User.find_each.to_a.combination(2).each do |sender_user, recipient_user|
    sender_user.accounts.each do |sender_account|
      recipient_user.accounts.each do |recipient_account|
        1.upto(2) do |i|
          params = { sender_amount: rand(50..200) * i, sender: sender_account, recipient: recipient_account }
          transaction = Transaction.new(params)
          transaction.save!
          transaction.complete
        end
      end
    end

    recipient_user.accounts.each do |recipient_account|
      sender_user.accounts.each do |sender_account|
        1.upto(2) do |i|
          params = { sender_amount: rand(50..200) * i, sender: recipient_account, recipient: sender_account }
          transaction = Transaction.new(params)
          transaction.save!
          transaction.complete
        end
      end
    end
  end
end
