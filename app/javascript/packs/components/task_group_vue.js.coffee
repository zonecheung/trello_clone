import axios from 'axios'
import Task from './task_vue.js'

export default
  props: ['task_group']

  template: '#task-group-vue-component-template'

  data: ->
    parent: this.$parent
    board: this.$parent.board

    target_board_id: this.$parent.board.id
    target_position: null

    active_modal_task_id: null
    editing_task_id: null

    show_new_task_form: false
    new_task: { title: '' }

  components:
    'task': Task

  created: ->
    @new_task.task_group_id = @task_group.id

  computed:
    targetBoard: ->
      pos = @$_taskGroup_findBoardIndexById(@target_board_id)
      @parent.boards[pos]

    taskGroupPositions: ->
      offset = if @target_board_id == @board.id then 0 else 1
      @parent.createRange(@targetBoard.task_groups.length + offset)

  methods:
    update: ->
      unless @task_group.title.trim() == ''
        that = this
        axios.patch(
          "/api/boards/#{@board.id}/task_groups/#{@task_group.id}",
          task_group:
            title: @task_group.title
        )
          .then (res) ->
            if that.parent.editing_task_group_id == that.task_group.id
              that.parent.editing_task_group_id = null
          .catch @parent.commonAxiosErrorHandler

    destroy: ->
      if confirm('Are you sure you want to delete this list?')
        that = this
        axios.delete("/api/boards/#{@board.id}/task_groups/#{@task_group.id}")
          .then (res) ->
            that.$_taskGroup_remove(that.board, that.task_group)
          .catch @parent.commonAxiosErrorHandler

    showMoveModal: ->
      @parent.active_modal_task_group_id = @task_group.id
      @target_board_id = @board.id
      @target_position = @$_taskGroup_findIndex(@board, @task_group) + 1

    move: ->
      current_position = @$_taskGroup_findIndex(@board, @task_group)
      unless @target_board_id == @board.id &&
             @target_position == current_position + 1
        that = this
        if @target_board_id == @board.id ||
           confirm('Are you sure you want to move this to another board?')
          axios.patch(
            "/api/boards/#{@board.id}/task_groups/#{@task_group.id}" +
              "/move_to_position",
            target_board_id: @target_board_id,
            position: @target_position
          )
            .then (res) ->
              if that.board.id == that.target_board_id
                # Move in current board.
                that.$_taskGroup_changePosition(
                  that.board, that.target_position - 1, current_position
                )
              else
                # Move to another board.
                that.$_taskGroup_moveToTargetBoard()
              that.parent.active_modal_task_group_id = null
            .catch @parent.commonAxiosErrorHandler

    createTask: ->
      unless @new_task.title.trim() == ''
        that = this
        axios.post(
          "/api/boards/#{@board.id}/task_groups/#{@task_group.id}/tasks",
          task: @new_task
        )
          .then (res) ->
            that.task_group.tasks.push(res.data)
            that.closeTaskForm()
          .catch @parent.commonAxiosErrorHandler

    closeTaskForm: ->
      @show_new_task_form = false
      @new_task.title = ''

    # Private methods.
    $_taskGroup_findBoardIndexById: (board_id) ->
      @parent.boards.findIndex (b) -> b.id == board_id

    $_taskGroup_findIndex: (board, task_group) ->
      board.task_groups.findIndex (tg) -> tg.id == task_group.id

    $_taskGroup_remove: (board, task_group) ->
      pos = @$_taskGroup_findIndex(board, task_group)
      board.task_groups.splice(pos, 1)

    $_taskGroup_changePosition: (board, target_position, current_position) ->
      task_group = board.task_groups[current_position]
      if target_position < current_position
        board.task_groups.splice(current_position, 1)
        board.task_groups.splice(target_position, 0, task_group)
      else
        board.task_groups.splice(target_position + 1, 0, task_group)
        board.task_groups.splice(current_position, 1)

    $_taskGroup_moveToTargetBoard: ->
      # Add to another board.
      @task_group.board_id = @target_board_id
      @targetBoard.task_groups
                  .splice(@target_position - 1, 0, @task_group)
      # Remove from current board.
      @$_taskGroup_remove(@board, @task_group)
