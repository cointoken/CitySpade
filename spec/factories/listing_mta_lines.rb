# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing_mta_line do
    listing nil
    mta_info_line nil
    listing_place nil
    distance 1.5
    duration 1.5
  end
end
