import axios from 'axios'
import TaskGroup from './task_group_vue.js'

export default
  props: ['board_id']

  template: '#board-vue-component-template'

  data: ->
    boards: []
    board: { title: '', task_groups: [] }

    new_board: { title: '' }

    creating: false
    editing: false

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
        if pos >= 0
          that.board = that.boards[pos]
          that.new_task_group.board_id = that.board_id
      .catch @commonAxiosErrorHandler

  methods:
    update: ->
      unless @board.title.trim() == ''
        that = this
        axios.patch(
          "/api/boards/#{@board.id}",
          board:
            title: @board.title
        )
          .then (res) ->
            that.editing = false
          .catch @commonAxiosErrorHandler

    destroy: ->
      if confirm('Are you sure you want to delete this board?')
        that = this
        axios.delete("/api/boards/#{@board.id}")
          .then (res) ->
            window.location.assign('/?board_id=0')
          .catch @commonAxiosErrorHandler

    create: ->
      unless @new_board.title.trim() == ''
        that = this
        axios.post(
          "/api/boards",
          board:
            title: @new_board.title
        )
          .then (res) ->
            that.creating = false
            window.location.assign("/?board_id=#{res.data.id}")
          .catch @commonAxiosErrorHandler

    redirectTo: (board_id) ->
      # NOTE: Ideally we can do this with :href in the link, but somehow it
      #       didn't re-initialize Vue and caused blank page.
      window.location.assign("/?board_id=#{board_id}")

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
          task_group:
            title: @new_task_group.title
            board_id: @board.id
        )
          .then (res) ->
            that.board.task_groups.push(res.data)
            that.closeTaskGroupForm()
          .catch @commonAxiosErrorHandler

    closeTaskGroupForm: ->
      @new_task_group.title = ''
      @show_new_task_group_form = false

    showInput: ->
      @editing = true
      @$nextTick ->
        @$refs.title.focus()

    showNewTaskGroupForm: ->
      @show_new_task_group_form = true
      @$nextTick ->
        @$refs.new_title.focus()
