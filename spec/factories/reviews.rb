# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :review do
    address "MyString"
    building_name "MyString"
    city "MyString"
    state "MyString"
    review_type 1
  end
end
