# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :review_street do
    review nil
    convenience 1
    living 1
    safety 1
    comment "MyText"
  end
end
