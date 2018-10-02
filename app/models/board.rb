class Board < ApplicationRecord
  DEFAULT_TASK_GROUPS = %i[todo doing done].freeze

  has_many :task_groups, dependent: :destroy
  has_many :tasks, through: :task_groups

  validates :title, presence: true, length: { maximum: 255 }

  after_create :create_default_task_groups

  private

  def create_default_task_groups
    DEFAULT_TASK_GROUPS.each do |symbol|
      self.task_groups.create(title: I18n.t("task_groups.#{symbol}"))
    end
  end
end
