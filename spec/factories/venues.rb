# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue do
    venue_type "MyString"
    venue_id 1
    building 1.5
    management 1.5
    convenience 1.5
    things_to_do 1.5
    safety 1.5
    ground 1.5
    quietness 1.5
    lat 1.5
    lng 1.5
    formatted_address "MyString"
  end
end
