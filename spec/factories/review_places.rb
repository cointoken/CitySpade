# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :review_place do
    review nil
    place_type "MyString"
    name "MyString"
    comment "MyText"
  end
end
