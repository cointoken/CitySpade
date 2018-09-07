# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page_view do
    page_type "MyString"
    page_id 1
    num 1
  end
end
