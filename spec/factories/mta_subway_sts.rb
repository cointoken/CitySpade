# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mta_subway_st do
    mta_subway_line nil
    name "MyString"
    long_name "MyString"
    num_name "MyString"
    location "MyString"
  end
end
