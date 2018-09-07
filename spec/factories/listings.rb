# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listing do
    title "MyString"
    unit "MyString"
    beds 1.0
    baths 1.0
    sq_ft 1.5
    contact_name "MyString"
    contact_tel "MyString"
    flag 1
    zipcode 10012
    lat 43
    lng -73
    price 1000
    origin_url '/'
  end
end
