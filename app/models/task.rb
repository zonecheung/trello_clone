class Task < ApplicationRecord
  belongs_to :task_group, touch: true

  acts_as_list scope: %i[task_group_id]

  validates :task_group_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }

  default_scope { order('position') }

  delegate :board,
           :board_id, to: :task_group

  def move_to_position(target_board_id, target_task_group_id, pos)
    move_to_task_group_if_applicable(target_board_id, target_task_group_id) &&
      self.insert_at(pos) != false # nil is returned when there's only one item.
  end

  private

  def move_to_task_group_if_applicable(target_board_id, target_task_group_id)
    return true if target_board_id == self.board_id &&
                   target_task_group_id == self.task_group_id
    return false unless valid_as_target?(target_board_id,
                                         target_task_group_id)

    self.remove_from_list &&
      self.update_attributes(task_group_id: target_task_group_id)
  end

  def valid_as_target?(target_board_id, target_task_group_id)
    target_board = Board.find_by_id(target_board_id)
    target_task_group = target_board.task_groups
                                    .find_by_id(target_task_group_id)

    if target_task_group.nil?
      self.errors.add(:task_group_id, I18n.t('shared.not_found'))
    end
    self.errors.blank?
  end
end
