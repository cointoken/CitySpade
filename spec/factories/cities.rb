# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :city do
    name "Acmar"
    state "AL"
    long_state "Alabama"
    country "US"
    min_zip "35004"
    max_zip "35004"
    lat 33.5841
    lng -86.5156
    hot nil
  end
end
