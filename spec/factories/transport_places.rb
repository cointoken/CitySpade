# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transport_place do
    name "MyString"
    place_type "MyString"
    lat 1.5
    lng 1.5
    political_area nil
  end
end
