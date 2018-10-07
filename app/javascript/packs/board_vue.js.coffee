import Vue from 'vue/dist/vue'
import axios from 'axios'

document.addEventListener 'DOMContentLoaded', ->
  axios.defaults.headers
       .common['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')

  vm = new Vue
    el: '#trello-clone-vue'

    data:
      boards: []
      board: { task_groups: [] }

      active_modal_task_group_id: null
      editing_task_group_id: null

      show_new_task_group_form: false
      new_task_group: { title: '' }

    created: ->
      axios.get('/api/boards')
        .then (res) ->
          vm.boards = res.data
          # Just a quick way to get the last updated board.
          vm.board = vm.boards[0]
          vm.new_task_group.board_id = vm.board.id
        .catch commonAxiosErrorHandler

    methods:
      createTaskGroup: ->
        unless @new_task_group.title.trim() == ''
          axios.post(
            "/api/boards/#{@board.id}/task_groups",
            task_group: @new_task_group
          )
            .then (res) ->
              vm.board.task_groups.push(res.data)
              vm.closeTaskGroupForm()
            .catch commonAxiosErrorHandler

      closeTaskGroupForm: ->
        @new_task_group.title = ''
        @show_new_task_group_form = false


commonAxiosErrorHandler = (err) ->
  console.log(err)
  alert(err)

createRange = (n) ->
  list = new Array()
  list.push(i) for i in [1..n]
  list


TaskGroup = Vue.component 'task-group',
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

  created: ->
    @new_task.task_group_id = @task_group.id

  computed:
    targetBoard: ->
      pos = @$_taskGroup_findBoardIndexById(@target_board_id)
      @parent.boards[pos]

    taskGroupPositions: ->
      offset = if @target_board_id == @board.id then 0 else 1
      createRange(@targetBoard.task_groups.length + offset)

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
          .catch commonAxiosErrorHandler

    destroy: ->
      if confirm('Are you sure you want to delete this list?')
        that = this
        axios.delete("/api/boards/#{@board.id}/task_groups/#{@task_group.id}")
          .then (res) ->
            that.$_taskGroup_remove(that.board, that.task_group)
          .catch commonAxiosErrorHandler

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
            .catch commonAxiosErrorHandler

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
          .catch commonAxiosErrorHandler

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


Task = Vue.component 'task',
  props: ['task']

  template: '#task-vue-component-template'

  data: ->
    parent: this.$parent
    board: this.$parent.board
    task_group: this.$parent.task_group

    target_board_id: this.$parent.board.id
    target_task_group_id: this.$parent.task_group.id
    target_position: null

    editing_task_id: null

  computed:
    targetBoard: ->
      pos = @$_task_findBoardIndexById(@target_board_id)
      @parent.parent.boards[pos]

    targetTaskGroup: ->
      board = @targetBoard
      pos = @$_task_findTaskGroupIndexById(board, @target_task_group_id)
      board.task_groups[pos]

    taskPositions: ->
      board = @targetBoard
      pos = @$_task_findTaskGroupIndexById(board, @target_task_group_id)
      offset = if @target_task_group_id == @task_group.id then 0 else 1
      createRange(board.task_groups[pos].tasks.length + offset)

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
          .catch commonAxiosErrorHandler

    destroy: ->
      if confirm('Are you sure you want to delete this card?')
        that = this
        axios.delete(
          "/api/boards/#{@board.id}/task_groups/#{@task_group.id}" +
            "/tasks/#{@task.id}"
        )
          .then (res) ->
            that.$_task_remove(that.task_group, that.task)
          .catch commonAxiosErrorHandler

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
            .catch commonAxiosErrorHandler

    # Private methods.
    $_task_findBoardIndexById: (board_id) ->
      @parent.parent.boards.findIndex (b) -> b.id == board_id

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
