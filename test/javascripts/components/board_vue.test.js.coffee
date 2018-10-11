import { shallowMount } from '@vue/test-utils'
import axios from 'axios'
import Board from '../../../app/javascript/packs/components/board_vue.js'

jest.mock('axios')

# We're unit testing, remove child components and template.
Board.components = {}
Board.template = '<div></div>'

describe 'Board component', ->
  beforeAll ->
    axios.get.mockResolvedValue(
      data: [
        { id: 1, title: 'Board 1' },
        { id: 2, title: 'Board 2', task_groups: [] },
        { id: 3, title: 'Board 3' }
      ]
    )

  it 'is a Vue instance', ->
    component = shallowMount(Board)
    expect(component.isVueInstance()).toBeTruthy()

  describe 'checking methods', ->
    component = null
    vm = null

    describe 'when component is created', ->
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

    describe 'when updating a board', ->
      beforeAll ->
        axios.patch.mockResolvedValue({})

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

    describe 'when destroying a board', ->
      beforeAll ->
        axios.delete.mockResolvedValue({})
        window.location.assign = jest.fn()

      beforeEach ->
        component = shallowMount(
          Board,
          propsData:
            board_id: 2
        )
        vm = component.vm

      describe 'when confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> true

        it 'should call axios.delete once', ->
          vm.$nextTick ->
            vm.destroy()
            vm.$nextTick ->
              expect(axios.delete.mock.calls.length).toEqual(1)
              expect(axios.delete.mock.calls[0]).toEqual(
                ['/api/boards/2']
              )

        it 'should redirect to certain page', ->
          vm.$nextTick ->
            vm.destroy()
            vm.$nextTick ->
              expect(window.location.assign).toBeCalledWith('/?board_id=0')

      describe 'when not confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> false

        it 'should not call axios.delete', ->
          vm.$nextTick ->
            vm.destroy()
            expect(axios.delete.mock.calls.length).toEqual(0)

    describe 'when creating a board', ->
      beforeAll ->
        axios.post.mockResolvedValue(data: { id: 777, name: 'Whiteboard' })
        window.location.assign = jest.fn()

      beforeEach ->
        component = shallowMount(Board)
        vm = component.vm
        vm.new_board.title = 'Whiteboard'

      it 'should call axios.post once', ->
        vm.$nextTick ->
          vm.create()
          vm.$nextTick ->
            expect(axios.post.mock.calls.length).toEqual(1)
            expect(axios.post.mock.calls[0]).toEqual(
              ['/api/boards', { board: { title: 'Whiteboard' } }]
            )

      it 'should set creating to false', ->
        vm.$nextTick ->
          vm.creating = true
          vm.create()
          vm.$nextTick ->
            expect(vm.creating).toEqual(false)

      it 'should redirect to certain page', ->
        vm.$nextTick ->
          vm.create()
          vm.$nextTick ->
            expect(window.location.assign).toBeCalledWith('/?board_id=777')

      it 'should not call axios.patch when the board.title is blank', ->
        vm.$nextTick ->
          vm.new_board.title = ''
          vm.create()
          expect(axios.post.mock.calls.length).toEqual(0)

    describe 'when creating a task group', ->
      beforeAll ->
        axios.post.mockResolvedValue(
          data: { id: 555, board_id: 2, name: 'Bucket List' }
        )

      beforeEach ->
        component = shallowMount(
          Board,
          propsData:
            board_id: 2
        )
        vm = component.vm

      it 'should call axios.post once', ->
        vm.$nextTick ->
          vm.new_task_group.title = 'Bucket List'
          expect(vm.board.task_groups.length).toEqual(0)
          vm.createTaskGroup()
          vm.$nextTick ->
            expect(axios.post.mock.calls.length).toEqual(1)
            expect(axios.post.mock.calls[0]).toEqual(
              ['/api/boards/2/task_groups',
               { task_group: { board_id: 2, title: 'Bucket List' } }]
            )

      it 'should add the new task group to board', ->
        vm.$nextTick ->
          size = vm.board.task_groups.length
          vm.new_task_group.title = 'Bucket List'
          vm.createTaskGroup()
          vm.$nextTick ->
            expect(vm.board.task_groups.length).toEqual(size + 1)
            expect(vm.board.task_groups.pop().id).toEqual(555)

      it 'should close the new task group form', ->
        vm.$nextTick ->
          vm.new_task_group.title = 'Bucket List'
          vm.show_new_task_group_form = true
          vm.createTaskGroup()
          vm.$nextTick ->
            expect(vm.new_task_group.title).toEqual('')
            expect(vm.show_new_task_group_form).toEqual(false)

      it 'should not call axios.post when the new task group\'s title is blank', ->
        vm.$nextTick ->
          vm.new_task_group.title = ''
          vm.createTaskGroup()
          expect(axios.post.mock.calls.length).toEqual(0)
