json.merge! board.attributes

unless no_task_groups
  json.task_groups do
    json.array! board.task_groups,
                partial: 'api/task_groups/task_group', as: :task_group
  end
end
