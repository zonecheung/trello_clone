json.array! @boards,
            partial: 'api/boards/board', as: :board,
            locals: { no_task_groups: @no_task_groups }
