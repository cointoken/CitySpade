# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :address_translator do
    low_num 1
    high_num 1
    street_name "MyString"
    nyc_bin 1
    borough "MyString"
    city "MyString"
    zipcode "MyString"
    building nil
    master_id 1
  end
end
