import Vue from 'vue/dist/vue'
import axios from 'axios'

$ ->
  axios.defaults.headers.common['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')

  vm = new Vue
    el: '#board-vue'

    data:
      boards: []
      board: { task_groups: [] }

      # Ideally these should be in TaskGroup, but we want 'global' state.
      active_menu_task_group_id: null
      editing_task_group_id: null
      active_modal_task_group_id: null

      showNewTaskGroupForm: false
      newTaskGroupTitle: ''

    created: ->
      axios.get('/api/boards')
        .then (res) ->
          vm.boards = res.data
          # Just a quick way to get the last updated board.
          vm.board = vm.boards[vm.boards.length - 1]
        .catch commonAxiosErrorHandler

    methods:
      openNewTaskGroupForm: ->
        @showNewTaskGroupForm = true

      createTaskGroup: ->
        unless @newTaskGroupTitle.trim() == ''
          axios.post(
            "/api/boards/#{@board.id}/task_groups",
            task_group:
              board_id: @board.id
              title: @newTaskGroupTitle
          )
            .then (res) ->
              vm.board.task_groups.push(res.data)
              vm.closeNewTaskGroupForm()
            .catch commonAxiosErrorHandler

      closeNewTaskGroupForm: ->
        @newTaskGroupTitle = ''
        @showNewTaskGroupForm = false


commonAxiosErrorHandler = (err) ->
  console.log(err)
  alert(err)


TaskGroup = Vue.component 'task-group',
  props: ['task_group']

  template: '#task-group-vue-component-template'

  data: ->
    parent: this.$parent
    board: this.$parent.board

  methods:
    update: (task_group) ->
      unless task_group.title.trim() == ''
        that = this
        axios.patch(
          "/api/boards/#{@board.id}/task_groups/#{task_group.id}",
          task_group:
            title: task_group.title
        )
          .then (res) ->
            if that.parent.editing_task_group_id == task_group.id
              that.parent.editing_task_group_id = null
          .catch commonAxiosErrorHandler

    destroy: (task_group) ->
      if confirm('Are you sure you want to delete this list?')
        that = this
        axios.delete("/api/boards/#{@board.id}/task_groups/#{task_group.id}")
          .then (res) ->
            pos = that.board.task_groups.findIndex (tg) ->
              tg.id == task_group.id
            that.board.task_groups.splice(pos, 1)
          .catch commonAxiosErrorHandler


Task = Vue.component 'task',
  props: ['task']

  template: '#task-vue-component-template'

