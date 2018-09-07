# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :disqu, :class => 'Disqus' do
    disqus_obj_type "MyString"
    disqus_obj_id 1
    thread_id 1
    post_id 1
  end
end
