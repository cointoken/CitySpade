# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing_detail do
    listing nil
    description "MyText"
  end
end
