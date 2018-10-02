class Task < ApplicationRecord
  belongs_to :task_group

  acts_as_list scope: %i[task_group_id]

  validates :task_group_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }
end
