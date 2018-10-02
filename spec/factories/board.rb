FactoryBot.define do
  factory :board do
    sequence(:title) { |n| "Title #{n}" }
  end
end
