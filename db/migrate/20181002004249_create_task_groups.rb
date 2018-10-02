class CreateTaskGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :task_groups do |t|
      t.references :board
      t.string :title
      t.integer :position
      t.timestamps
    end
    add_index :task_groups, %i[board_id position]
  end
end
