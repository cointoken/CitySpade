# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account_omniauth do
    account nil
    provider "MyString"
    uid "MyString"
  end
end
