import { shallowMount } from '@vue/test-utils'
import axios from 'axios'
import TaskGroup from '../../../app/javascript/packs/components/task_group_vue.js'

jest.mock('axios')

# We're unit testing, remove child components and template.
TaskGroup.components = {}
TaskGroup.template = '<div></div>'

describe 'TaskGroup component', ->
  task_group1 = { id: 1, title: 'Santa\'s List' }
  task_group2 = { id: 2, title: 'Bucket List', tasks: [] }
  task_group3 = { id: 3, title: 'Grinch\'s List' }
  boards = [
    { id: 1, title: 'Board 1', task_groups: [] },
    { id: 2, title: 'Board 2', task_groups: [
        task_group1, task_group2, task_group3
      ] },
    { id: 3, title: 'Board 3', task_groups: [] }
  ]
  $parent = {
    boards: boards
    board: boards[1]
  }

  component = null
  vm = null

  beforeEach ->
    component = shallowMount(
      TaskGroup,
      propsData:
        task_group: task_group2
      mocks:
        $parent
    )
    vm = component.vm

  it 'is a Vue instance', ->
    expect(component.isVueInstance()).toBeTruthy()

  it 'should have the correct board', ->
    vm.$nextTick ->
      expect(vm.board.id).toEqual(2)
      expect(vm.board.task_groups.length).toEqual(3)

  it 'should set certain data when component is created', ->
    vm.$nextTick ->
      expect(vm.new_task.task_group_id).toEqual(2)

  describe 'checking methods', ->
    describe 'when updating a task_group', ->
      beforeAll ->
        axios.patch.mockResolvedValue({})

      it 'should call axios.patch once', ->
        vm.$nextTick ->
          vm.task_group.title = 'Todo List'
          vm.update()
          vm.$nextTick ->
            expect(axios.patch.mock.calls.length).toEqual(1)
            expect(axios.patch.mock.calls[0]).toEqual(
              ['/api/boards/2/task_groups/2',
               { task_group: { title: 'Todo List' } }]
            )

      it 'should reset the editing flag', ->
        vm.$nextTick ->
          vm.task_group.title = 'Todo List'
          vm.parent.editing_task_group_id = vm.task_group.id
          vm.update()
          vm.$nextTick ->
            expect(vm.parent.editing_task_group_id).toEqual(null)

      it 'should not call the axios.patch if the title is blank', ->
        vm.$nextTick ->
          vm.task_group.title = ''
          vm.update()
          expect(axios.patch.mock.calls.length).toEqual(0)

    describe 'when destroying a task_group', ->
      beforeAll ->
        axios.delete.mockResolvedValue({})

      describe 'when confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> true

        it 'should remove task_group from board', ->
          vm.$nextTick ->
            expect(vm.board.task_groups.length).toEqual(3)
            vm.destroy()
            vm.$nextTick ->
              expect(vm.board.task_groups.length).toEqual(2)

        it 'should call axios.delete once', ->
          vm.$nextTick ->
            vm.destroy()
            vm.$nextTick ->
              expect(axios.delete.mock.calls.length).toEqual(1)
              expect(axios.delete.mock.calls[0]).toEqual(
                ['/api/boards/2/task_groups/2']
              )

      describe 'when not confirmed in the dialog', ->
        beforeEach ->
          global.confirm = jest.fn -> false

        it 'should not call axios.delete', ->
          vm.$nextTick ->
            vm.destroy()
            expect(axios.delete.mock.calls.length).toEqual(0)

    describe 'when moving a task_group', ->
      beforeAll ->
        axios.patch.mockResolvedValue({})

      beforeEach ->
        # Re-assign because the object was modified by previous operations.
        vm.board.task_groups = [task_group1, task_group2, task_group3]

      it 'should have 3 task_groups in the board', ->
        vm.$nextTick ->
          expect(vm.board.task_groups.length).toEqual(3)

      describe 'in the same board', ->
        beforeEach ->
          vm.target_board_id = vm.board.id

        describe 'when position is not changed', ->
          beforeEach ->
            vm.target_position = 2

          it 'should not call axios.patch', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(axios.patch.mock.calls.length).toEqual(0)

          it 'should not change the position in current board', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.board.task_groups[1]).toEqual(task_group2)

        describe 'when the position is changed', ->
          beforeEach ->
            vm.target_position = 1

          it 'should call axios.patch once', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(axios.patch.mock.calls.length).toEqual(1)
                expect(axios.patch.mock.calls[0]).toEqual(
                  ['/api/boards/2/task_groups/2/move_to_position',
                   { target_board_id: 2, position: 1 }]
                )

          it 'should change the position in current board', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.board.task_groups[0]).toEqual(task_group2)

          it 'should reset the active modal flag', ->
            vm.$nextTick ->
              vm.parent.active_modal_task_group_id = 2
              vm.move()
              vm.$nextTick ->
                expect(vm.parent.active_modal_task_group_id).toEqual(null)

      describe 'to another board', ->
        beforeEach ->
          vm.target_board_id = 3
          vm.target_position = 1

        describe 'when confirmed in the dialog', ->
          beforeEach ->
            global.confirm = jest.fn -> true
            # Reset the task_groups in target board.
            vm.boards[2].task_groups = []

          it 'should call axios.patch once', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(axios.patch.mock.calls.length).toEqual(1)
                expect(axios.patch.mock.calls[0]).toEqual(
                  ['/api/boards/2/task_groups/2/move_to_position',
                   { target_board_id: 3, position: 1 }]
                )

          it 'should be removed from current board', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.board.task_groups.length).toEqual(2)
                expect(vm.board.task_groups).not.toContain(task_group2)

          it 'should be added to another board', ->
            vm.$nextTick ->
              vm.move()
              vm.$nextTick ->
                expect(vm.boards[2].task_groups.length).toEqual(1)
                expect(vm.boards[2].task_groups).toContain(task_group2)

        describe 'when not confirmed in the dialog', ->
          beforeEach ->
            global.confirm = jest.fn -> false

          it 'should not call axios.patch', ->
            vm.$nextTick ->
              vm.move()
              expect(axios.patch.mock.calls.length).toEqual(0)

    describe 'when creating a task', ->
      beforeAll ->
        axios.post.mockResolvedValue(
          data: { id: 555, task_group_id: 2, name: 'Random Task' }
        )

      it 'should call axios.post once', ->
        vm.$nextTick ->
          vm.new_task.title = 'Random Task'
          expect(vm.task_group.tasks.length).toEqual(0)
          vm.createTask()
          vm.$nextTick ->
            expect(axios.post.mock.calls.length).toEqual(1)
            expect(axios.post.mock.calls[0]).toEqual(
              ['/api/boards/2/task_groups/2/tasks',
               { task: { task_group_id: 2, title: 'Random Task' } }]
            )

      it 'should add the new task to task_group', ->
        vm.$nextTick ->
          size = vm.task_group.tasks.length
          vm.new_task.title = 'Random Task'
          vm.createTask()
          vm.$nextTick ->
            expect(vm.task_group.tasks.length).toEqual(size + 1)
            expect(vm.task_group.tasks.pop().id).toEqual(555)

      it 'should close the new task form', ->
        vm.$nextTick ->
          vm.new_task.title = 'Random Task'
          vm.show_new_task_form = true
          vm.createTask()
          vm.$nextTick ->
            expect(vm.new_task.title).toEqual('')
            expect(vm.show_new_task_form).toEqual(false)

      it 'should not call axios.post when the new task\'s title is blank', ->
        vm.$nextTick ->
          vm.new_task.title = ''
          vm.createTask()
          expect(axios.post.mock.calls.length).toEqual(0)
