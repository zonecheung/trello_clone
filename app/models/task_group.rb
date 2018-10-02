class TaskGroup < ApplicationRecord
  belongs_to :board
  has_many :tasks, dependent: :destroy

  acts_as_list scope: %i[board_id]

  validates :board_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }
end
