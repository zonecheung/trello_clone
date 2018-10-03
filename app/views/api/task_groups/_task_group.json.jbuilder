json.merge! task_group.attributes

json.tasks do
  json.array! task_group.tasks, partial: 'api/tasks/task', as: :task
end
