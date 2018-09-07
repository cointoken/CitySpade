# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :neighborhood do
    city "MyString"
    borough "MyString"
    name "MyString"
    hot 1
  end
end
