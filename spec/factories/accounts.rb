FactoryGirl.define do
  factory :account do
    sequence(:email){|n| "#{n}_account@example.com" }
    sequence(:first_name){|n| "first_name_#{n}" }
    sequence(:last_name){|n| "last_name_#{n}" }
    role 'user'
    password 'password'
    password_confirmation 'password'
  end

  factory :admin, parent: :account do
    role 'admin'
  end
end
