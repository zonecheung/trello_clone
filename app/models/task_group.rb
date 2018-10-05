class TaskGroup < ApplicationRecord
  belongs_to :board
  has_many :tasks, dependent: :destroy

  acts_as_list scope: %i[board_id]

  validates :board_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }

  default_scope { order('position') }

  def move_to_position(target_board_id, pos)
    move_to_board_if_applicable(target_board_id) &&
      self.insert_at(pos) != false # nil is returned when there's only one item.
  end

  private

  def move_to_board_if_applicable(target_board_id)
    return true if target_board_id == self.board_id
    return false unless valid_as_target?(target_board_id)

    self.remove_from_list &&
      self.update_attributes(board_id: target_board_id)
  end

  def valid_as_target?(target_board_id)
    target_board = Board.find_by_id(target_board_id)
    self.errors.add(:board_id, I18n.t('shared.not_found')) if target_board.nil?
    self.errors.blank?
  end
end
