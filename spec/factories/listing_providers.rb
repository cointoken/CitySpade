# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing_provider do
    listing nil
    provider_id 1
    client_name "MyString"
  end
end
