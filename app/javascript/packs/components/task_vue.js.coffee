import axios from 'axios'

export default
  props: ['task']

  template: '#task-vue-component-template'

  data: ->
    parent: @$parent
    board: @$parent.board
    boards: @$parent.boards
    task_group: @$parent.task_group

    target_board_id: @$parent.board.id
    target_task_group_id: @$parent.task_group.id
    target_position: null

    editing_task_id: null

  computed:
    targetBoard: ->
      pos = @$_task_findBoardIndexById(@target_board_id)
      @boards[pos]

    targetTaskGroup: ->
      board = @targetBoard
      pos = @$_task_findTaskGroupIndexById(board, @target_task_group_id)
      board.task_groups[pos]

    taskPositions: ->
      board = @targetBoard
      pos = @$_task_findTaskGroupIndexById(board, @target_task_group_id)
      offset = if @target_task_group_id == @task_group.id then 0 else 1
      @createRange(board.task_groups[pos].tasks.length + offset)

  methods:
    update: ->
      unless @task.title.trim() == ''
        that = this
        axios.patch(
          "/api/boards/#{@board.id}/task_groups/#{@task_group.id}/tasks" +
            "/#{@task.id}",
          task:
            title: @task.title
        )
          .then (res) ->
            if that.parent.editing_task_id == that.task.id
              that.parent.editing_task_id = null
          .catch @commonAxiosErrorHandler

    destroy: ->
      if confirm('Are you sure you want to delete this card?')
        that = this
        axios.delete(
          "/api/boards/#{@board.id}/task_groups/#{@task_group.id}" +
            "/tasks/#{@task.id}"
        )
          .then (res) ->
            that.$_task_remove(that.task_group, that.task)
          .catch @commonAxiosErrorHandler

    showMoveModal: ->
      @parent.active_modal_task_id = @task.id
      @target_board_id = @board.id
      @target_task_group_id = @task_group.id
      @target_position = @$_task_findIndex(@task_group, @task) + 1

    changeTargetBoard: ->
      board = @targetBoard
      @target_task_group_id = board.task_groups[0].id

    move: ->
      current_position = @$_task_findIndex(@task_group, @task)
      unless @target_board_id == @board.id &&
             @target_task_group_id == @task_group.id &&
             @target_position == current_position + 1
        that = this
        if @target_board_id == @board.id ||
           confirm('Are you sure you want to move this to another board?')
          axios.patch(
            "/api/boards/#{@board.id}/task_groups/#{@task_group.id}" +
              "/tasks/#{@task.id}/move_to_position",
            target_board_id: @target_board_id,
            target_task_group_id: @target_task_group_id,
            position: @target_position
          )
            .then (res) ->
              if that.board.id == that.target_board_id &&
                 that.task_group.id == that.target_task_group_id
                # Move in current task_group.
                that.$_task_changePosition(
                  that.task_group, that.target_position - 1, current_position
                )
              else
                that.$_task_moveToTargetTaskGroup()
              that.parent.active_modal_task_id = null
            .catch @commonAxiosErrorHandler

    commonAxiosErrorHandler: (err) ->
      @parent.commonAxiosErrorHandler(err)

    createRange: (n) ->
      @parent.createRange(n)

    # Private methods.
    $_task_findBoardIndexById: (board_id) ->
      @boards.findIndex (b) -> b.id == board_id

    $_task_findTaskGroupIndexById: (board, task_group_id) ->
      board.task_groups.findIndex (tg) -> tg.id == task_group_id

    $_task_findIndex: (task_group, task) ->
      task_group.tasks.findIndex (t) -> t.id == task.id

    $_task_remove: (task_group, task) ->
      pos = @$_task_findIndex(task_group, task)
      task_group.tasks.splice(pos, 1)

    $_task_changePosition: (task_group, target_position, current_position) ->
      task = task_group.tasks[current_position]
      if target_position < current_position
        task_group.tasks.splice(current_position, 1)
        task_group.tasks.splice(target_position, 0, task)
      else
        task_group.tasks.splice(target_position + 1, 0, task)
        task_group.tasks.splice(current_position, 1)

    $_task_moveToTargetTaskGroup: ->
      # Add to another task_group.
      @task.task_group_id = @target_task_group_id
      @targetTaskGroup.tasks
                      .splice(@target_position - 1, 0, @task)
      # Remove from current task_group.
      @$_task_remove(@task_group, @task)
