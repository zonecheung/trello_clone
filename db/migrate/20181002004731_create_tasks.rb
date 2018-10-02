class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.references :task_group
      t.string :title
      t.integer :position
      t.timestamps
    end
    add_index :tasks, %i[task_group_id position]
  end
end
