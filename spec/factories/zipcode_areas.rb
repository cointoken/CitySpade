# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :zipcode_area do
    zipcode "MyString"
    political_area nil
  end
end
