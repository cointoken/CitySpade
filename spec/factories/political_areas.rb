# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :political_area do
    long_name "MyString"
    short_name "MyString"
    target "country"
    parent_id nil
  end
end
