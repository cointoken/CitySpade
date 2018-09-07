# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :review_apartment do
    review nil
    beds 1
    baths 1
    price 1.5
    comment "MyText"
  end
end
