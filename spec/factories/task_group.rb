FactoryBot.define do
  factory :task_group do
    board
    sequence(:title) { |n| "Title #{n}" }
  end
end
