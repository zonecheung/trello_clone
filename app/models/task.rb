class Task < ApplicationRecord
  belongs_to :task_group

  acts_as_list scope: %i[task_group_id]

  validates :task_group_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }

  default_scope { order('position') }

  def move_to_position(target_task_group_id, pos)
    move_to_task_group_if_applicable(target_task_group_id) &&
      self.insert_at(pos)
  end

  private

  def move_to_task_group_if_applicable(target_task_group_id)
    return true if target_task_group_id == self.task_group_id
    return false unless valid_as_target?(target_task_group_id)

    self.remove_from_list &&
      self.update_attributes(task_group_id: target_task_group_id)
  end

  def valid_as_target?(target_task_group_id)
    target_task_group = TaskGroup.find_by_id(target_task_group_id)
    if target_task_group.nil?
      self.errors.add(:task_group_id,
                      I18n.t('task_groups.not_found'))
    elsif target_task_group.board_id != self.task_group.board_id
      self.errors.add(:task_group_id,
                      I18n.t('task_groups.does_not_belong_to_same_board'))
    end
    self.errors.blank?
  end
end
