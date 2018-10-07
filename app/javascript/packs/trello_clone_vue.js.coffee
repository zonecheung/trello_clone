import Vue from 'vue/dist/vue'
import axios from 'axios'
import Board from './components/board_vue.js'

document.addEventListener 'DOMContentLoaded', ->
  axios.defaults.headers
       .common['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content')

  vm = new Vue
    el: '#trello-clone-vue'

    components:
      'board': Board
