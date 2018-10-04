import Vue from 'vue/dist/vue'
import axios from 'axios'

$ ->
  axios.defaults.headers.common['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')

  vm = new Vue
    el: '#board-vue'

    data:
      board: { task_groups: [] }
      showNewTaskGroupForm: false
      newTaskGroupTitle: ''

    created: ->
      axios.get('/api/boards/latest')
        .then (res) ->
          vm.board = res.data
        .catch @commonAxiosErrorHandler

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
            .catch @commonAxiosErrorHandler

      closeNewTaskGroupForm: ->
        @newTaskGroupTitle = ''
        @showNewTaskGroupForm = false

      commonAxiosErrorHandler: (err) ->
        console.log(err)
        alert(err)
