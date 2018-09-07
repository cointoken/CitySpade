# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transport_distance do
    listing nil
    transport_place nil
    duration 1
    distance 1
  end
end
