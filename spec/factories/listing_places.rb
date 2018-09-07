# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing_place do
    name "MyString"
    target "MyString"
    lat 1.5
    lng 1.5
    listing nil
  end
end
