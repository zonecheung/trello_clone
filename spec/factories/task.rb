FactoryBot.define do
  factory :task do
    task_group
    sequence(:title) { |n| "Title #{n}" }
  end
end
