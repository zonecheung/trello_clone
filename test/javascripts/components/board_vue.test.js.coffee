import { shallowMount } from '@vue/test-utils'
import axios from 'axios'
import Board from '../../../app/javascript/packs/components/board_vue.js'

jest.mock('axios')

# We're unit testing, remove additional components and template.
Board.components = {}
Board.template = '<div></div>'

describe 'Board component', ->
  axios.get.mockResolvedValue(
    data: [
      { id: 1, title: 'Board 1' },
      { id: 2, title: 'Board 2' },
      { id: 3, title: 'Board 3' }
    ]
  )

  it 'is a Vue instance', ->
    component = shallowMount(Board)
    expect(component.isVueInstance()).toBeTruthy()

  describe 'when component is created', ->
    component = null
    vm = null

    describe 'without the board_id set in props', ->
      beforeEach ->
        component = shallowMount(Board)
        vm = component.vm

      it 'is expected to call axios.get once', ->
        expect(axios.get.mock.calls.length).toEqual(1)
        expect(axios.get.mock.calls[0]).toEqual(['/api/boards'])

      it 'should set the boards data', ->
        vm.$nextTick ->
          expect(vm.boards.length).toEqual(3)

      it 'should not set the current board yet', ->
        vm.$nextTick ->
          expect(vm.board.id).toBeUndefined()

    describe 'with board_id is specified in props', ->
      beforeEach ->
        component = shallowMount(
          Board,
          propsData:
            board_id: 2
        )
        vm = component.vm

      it 'should assign the board', ->
        component.vm.$nextTick ->
          expect(component.vm.board.id).toEqual(2)

  describe 'when updating the board', ->
    axios.patch.mockResolvedValue({})

    component = null
    vm = null

    beforeEach ->
      component = shallowMount(
        Board,
        propsData:
          board_id: 2
      )
      vm = component.vm

    it 'should set the editing to false', ->
      vm.$nextTick ->
        vm.editing = true
        vm.update()
        vm.$nextTick ->
          expect(vm.editing).toEqual(false)

    it 'should call axios.patch once', ->
      vm.$nextTick ->
        vm.board.title = 'Blackboard'
        vm.update()
        vm.$nextTick ->
          expect(axios.patch.mock.calls.length).toEqual(1)
          expect(axios.patch.mock.calls[0]).toEqual(
            ['/api/boards/2', { board: { title: 'Blackboard' } }]
          )

    it 'should not call axios.patch when the board.title is blank', ->
      vm.$nextTick ->
        vm.board.title = ''
        vm.update()
        expect(axios.patch.mock.calls.length).toEqual(0)
