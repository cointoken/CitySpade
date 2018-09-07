# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :photo do
    imageable_type "MyString"
    imageable_id 1
    image "MyString"
  end
end
