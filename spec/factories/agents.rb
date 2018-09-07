# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :agent do
    broker nil
    name "John"
    tel "986792355"
  end
end
