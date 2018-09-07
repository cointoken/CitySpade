# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reputation do
    account_id 1
    reputable_type "MyString"
    reputable_id 1
    type ""
  end
end
