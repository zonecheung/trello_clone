import axios from 'axios'
import TaskGroup from './task_group_vue.js'

export default
  props: ['board_id']

  template: '#board-vue-component-template'

  data: ->
    boards: []
    board: { title: '', task_groups: [] }

    active_modal_task_group_id: null
    editing_task_group_id: null

    show_new_task_group_form: false
    new_task_group: { title: '' }

  components:
    'task-group': TaskGroup

  created: ->
    that = this
    axios.get('/api/boards')
      .then (res) ->
        that.boards = res.data
        pos = that.boards.findIndex (b) -> b.id == that.board_id
        that.board = that.boards[pos]
        that.new_task_group.board_id = that.board_id
      .catch @commonAxiosErrorHandler

  methods:
    commonAxiosErrorHandler: (err) ->
      console.log(err)
      alert(err)

    createRange: (n) ->
      list = new Array()
      list.push(i) for i in [1..n]
      list

    createTaskGroup: ->
      unless @new_task_group.title.trim() == ''
        that = this
        axios.post(
          "/api/boards/#{@board.id}/task_groups",
          task_group: @new_task_group
        )
          .then (res) ->
            that.board.task_groups.push(res.data)
            that.closeTaskGroupForm()
          .catch @commonAxiosErrorHandler

    closeTaskGroupForm: ->
      @new_task_group.title = ''
      @show_new_task_group_form = false


